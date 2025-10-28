import * as admin from 'firebase-admin';
import {onCall, onRequest, HttpsError} from 'firebase-functions/v2/https';
import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {setGlobalOptions} from 'firebase-functions/v2';
import Stripe from 'stripe';
import sgMail from '@sendgrid/mail';

admin.initializeApp();
setGlobalOptions({
  maxInstances: 10,
  region: 'us-central1',
  timeoutSeconds: 60,
});

// Read Stripe key from runtime config: functions:config:set stripe.secret=sk_test_...
const stripeSecret = process.env.STRIPE_SECRET;
if (!stripeSecret) {
  console.warn('Stripe secret not set. Set STRIPE_SECRET env variable');
}
const stripe = new Stripe(stripeSecret || 'sk_test_missing', { apiVersion: '2024-06-20' });

// Optional: SendGrid for email notifications
const sendgridKey = process.env.SENDGRID_API_KEY;
const sendgridFrom = process.env.SENDGRID_FROM;
if (sendgridKey) {
  try { sgMail.setApiKey(sendgridKey); } catch (e) { console.warn('Failed to set SendGrid API key'); }
}

// Optional: Mailchimp for lead sync
const mailchimpApiKey = process.env.MAILCHIMP_API_KEY;
const mailchimpListId = process.env.MAILCHIMP_LIST_ID;
const mailchimpServerPrefix = process.env.MAILCHIMP_SERVER_PREFIX; // e.g., 'us1'

// Optional: Slack webhook for notifications
const slackWebhookUrl = process.env.SLACK_WEBHOOK_URL;

// Admin emails for weekly reports
const adminEmails = process.env.ADMIN_EMAILS?.split(',') || [];

// ========================================
// PAYMENT FUNCTIONS
// ========================================

export const createCheckoutSession = onCall(async (request) => {
  try {
    // Enforce auth (recommended)
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const amount = Number(request.data?.amount);
    const currency = (request.data?.currency || 'usd').toString();
    const title = (request.data?.title || 'Invoice').toString();
    const description = (request.data?.description || '').toString();
    const invoiceId = (request.data?.invoiceId || '').toString();
    const userId = request.auth.uid;

    if (!amount || amount <= 0) {
      throw new HttpsError('invalid-argument', 'Amount must be a positive integer in the smallest currency unit');
    }

    const successUrl = request.data?.successUrl || 'https://project-bridge-cm.web.app/payments/success';
    const cancelUrl = request.data?.cancelUrl || 'https://project-bridge-cm.web.app/payments/cancel';

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      success_url: successUrl + '?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: cancelUrl,
      metadata: {
        invoiceId,
        userId,
      },
      line_items: [
        {
          price_data: {
            currency,
            unit_amount: amount, // in cents
            product_data: {
              name: title,
              description,
            },
          },
          quantity: 1,
        },
      ],
    });

    return { url: session.url };
  } catch (err: any) {
    console.error('createCheckoutSession error', err);
    if (err instanceof HttpsError) throw err;
    throw new HttpsError('internal', err?.message || 'Unknown error');
  }
});

// Webhook to mark invoices paid. For full security, set STRIPE_WEBHOOK_SECRET and verify signatures.
export const stripeWebhook = onRequest(async (request, response) => {
  try {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    let event: Stripe.Event;

    // If secret is configured, verify signature. Otherwise, accept raw JSON (not recommended for production).
    if (webhookSecret && request.headers['stripe-signature']) {
      const sig = request.headers['stripe-signature'] as string;
      const rawBody = request.rawBody || Buffer.from(JSON.stringify(request.body));
      event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
    } else {
      event = request.body as Stripe.Event;
    }

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      const invoiceId = (session.metadata?.invoiceId || '').toString();
      const userId = (session.metadata?.userId || '').toString();
      const amountTotal = session.amount_total ?? null;
      if (invoiceId) {
        await admin.firestore().collection('invoices').doc(invoiceId).set({
          status: 'paid',
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          amountTotal,
          userId,
        }, { merge: true });
      }
    }

    response.json({ received: true });
  } catch (e: any) {
    console.error('stripeWebhook error', e);
    response.status(400).send('Webhook error');
  }
});


// ========================================
// NOTIFICATION FUNCTIONS
// ========================================

/**
 * Send notification when a new project update is posted
 */
export const onProjectUpdate = onDocumentCreated('updates/{updateId}', async (event) => {
  const update = event.data?.data();
  if (!update) return;
  
  const projectId = update.projectId;
  const message = update.message || 'New update posted';

  try {
    // Get project details
    const projectDoc = await admin.firestore()
      .collection('projects').doc(projectId).get();
    
    if (!projectDoc.exists) {
      console.log('Project not found:', projectId);
      return;
    }

    const project = projectDoc.data();
    const customerId = project?.assignedCustomerId;

    if (!customerId) {
      console.log('No customer assigned to project');
      return;
    }

    // Get customer's FCM token
    const userDoc = await admin.firestore()
      .collection('users').doc(customerId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', customerId);
      return;
    }

    // Check notification preferences
    const prefs = userDoc.data();
    if (prefs?.notif_projectUpdates === false) {
      console.log('User has disabled project update notifications');
      return;
    }

    // Send notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '📸 New Project Update',
        body: message,
      },
      data: {
        projectId: projectId,
        updateId: event.params.updateId,
        type: 'project_update',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    console.log('Notification sent successfully to:', customerId);
  } catch (error) {
    console.error('Error sending project update notification:', error);
  }
});

/**
 * Send notification when a new file/photo is uploaded
 */
export const onFileUpload = onDocumentCreated('files/{fileId}', async (event) => {
  const file = event.data?.data();
  if (!file) return;
  
  const projectId = file.projectId;
  const fileName = file.fileName || 'Unknown file';
  const uploadedBy = file.uploadedBy;

  if (!projectId) {
    console.log('File not associated with a project');
    return;
  }

  try {
    // Get project details
    const projectDoc = await admin.firestore()
      .collection('projects').doc(projectId).get();
    
    if (!projectDoc.exists) return;

    const project = projectDoc.data();
    const customerId = project?.assignedCustomerId;

    // Don't notify the uploader
    if (!customerId || customerId === uploadedBy) return;

    // Get customer's FCM token
    const userDoc = await admin.firestore()
      .collection('users').doc(customerId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) return;

    // Send notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '📁 New File Uploaded',
        body: fileName,
      },
      data: {
        projectId: projectId,
        fileId: event.params.fileId,
        type: 'file_upload',
      },
    });

    console.log('File upload notification sent');
  } catch (error) {
    console.error('Error sending file upload notification:', error);
  }
});

/**
 * Send notification when a new invoice is created
 */
export const onInvoiceCreated = onDocumentCreated('invoices/{invoiceId}', async (event) => {
  const invoice = event.data?.data();
  if (!invoice) return;
  
  const customerId = invoice.userId; // User who should pay
  const amount = invoice.amount || 0;
  const title = invoice.title || 'Invoice';

  try {
    const userDoc = await admin.firestore()
      .collection('users').doc(customerId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) return;

    // Check preferences
    const prefs = userDoc.data();
    if (prefs?.notif_invoices === false) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '💵 New Invoice',
        body: `${title} - $${amount.toFixed(2)}`,
      },
      data: {
        invoiceId: event.params.invoiceId,
        type: 'invoice',
      },
    });

    console.log('Invoice notification sent');
  } catch (error) {
    console.error('Error sending invoice notification:', error);
  }
});

/**
 * Send notification when a new message is received
 */
export const onNewMessage = onDocumentCreated('messages/{messageId}', async (event) => {
  const message = event.data?.data();
  if (!message) return;
  
  const recipientId = message.recipientId;
  const senderId = message.senderId;
  const text = message.text || 'New message';

  if (!recipientId || !senderId) return;

  try {
    const [userDoc, senderDoc] = await Promise.all([
      admin.firestore().collection('users').doc(recipientId).get(),
      admin.firestore().collection('users').doc(senderId).get(),
    ]);

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    // Check preferences
    const prefs = userDoc.data();
    if (prefs?.notif_messages === false) return;

    const senderName = senderDoc.data()?.name || 'Someone';

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: `💬 ${senderName}`,
        body: text,
      },
      data: {
        messageId: event.params.messageId,
        senderId: senderId,
        type: 'message',
      },
    });

    console.log('Message notification sent');
  } catch (error) {
    console.error('Error sending message notification:', error);
  }
});


// ========================================
// GENERIC NOTIFICATION FANOUT
// ========================================

/**
 * On creation of a document in /notifications, send FCM to the target user's devices.
 * Document format suggestion:
 * {
 *   userId: string,
 *   title: string,
 *   body: string,
 *   type: 'task'|'task_update'|'check_in'|'contract_completed'|string,
 *   data: { ... },
 *   createdAt: serverTimestamp(),
 *   read: false
 * }
 */
export const sendOnNotificationCreate = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const notif = event.data?.data() as any;
  if (!notif) return;
  
  const userId = notif?.userId as string | undefined;
  if (!userId) {
    console.log('Notification missing userId');
    return;
  }

  // Collect tokens from users/{uid}/tokens
  const tokensSnap = await admin.firestore()
    .collection('users').doc(userId)
    .collection('tokens').get();
  const tokens = tokensSnap.docs.map(d => (d.data()?.token as string | undefined)).filter(Boolean) as string[];

  // Back-compat: fall back to a single fcmToken field on the user doc
  if (tokens.length === 0) {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const legacy = userDoc.data()?.fcmToken as string | undefined;
    if (legacy) tokens.push(legacy);
  }

  if (tokens.length === 0) {
    console.log('No tokens for user', userId);
  } else {
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: notif.title || 'Notification',
        body: notif.body || '',
      },
      data: {
        ...(notif.data || {}),
        type: (notif.type || 'custom').toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    };
    const resp = await admin.messaging().sendEachForMulticast(message);
    console.log('FCM sent: success', resp.successCount, 'failure', resp.failureCount);

    // Clean up invalid tokens
    const invalidErrors = new Set([
      'messaging/registration-token-not-registered',
      'messaging/invalid-registration-token',
    ]);
    const removals: Promise<any>[] = [];
    resp.responses.forEach((r, idx) => {
      if (!r.success && r.error && invalidErrors.has(r.error.code)) {
        const badToken = tokens[idx];
        console.log('Removing invalid token', badToken, 'for user', userId, 'reason', r.error.code);
        const userTokensRef = admin.firestore().collection('users').doc(userId).collection('tokens');
        removals.push(
          userTokensRef.where('token', '==', badToken).get().then((qs) => Promise.all(qs.docs.map(d => d.ref.delete())))
        );
      }
    });
    if (removals.length) await Promise.all(removals);
  }

  // Optional email via SendGrid
  if (sendgridKey && sendgridFrom) {
    try {
      const user = await admin.auth().getUser(userId).catch(() => null);
      const email = user?.email;
      if (email) {
        await sgMail.send({
          to: email,
          from: sendgridFrom,
          subject: notif.title || 'Notification',
          text: notif.body || '',
          html: `<p>${(notif.body || '')}
            </p><pre style="background:#f5f5f5;padding:12px">${JSON.stringify(notif.data || {}, null, 2)}</pre>`,
        });
        console.log('Email sent to', email);
      }
    } catch (e) {
      console.warn('Email send failed', e);
    }
  }
});

// ========================================
// CONTRACT COMPLETION (optional schema)
// ========================================

/**
 * If you maintain a /contracts collection with a status field, this will
 * create notifications when a contract transitions to 'completed'.
 */
export const onContractCompleted = onDocumentUpdated('contracts/{contractId}', async (event) => {
  const before = event.data?.before.data() as any;
  const after = event.data?.after.data() as any;
  if (!before || !after) return;
  if ((before.status || '').toString().toLowerCase() === 'completed') return;
  if ((after.status || '').toString().toLowerCase() !== 'completed') return;

  const title = 'Contract completed';
  const body = after.title ? `${after.title} has been completed.` : 'A contract has been completed.';

  const recipients: string[] = [];
  if (Array.isArray(after.userIds)) recipients.push(...after.userIds);
  if (after.clientId) recipients.push(after.clientId);
  if (after.contractorId) recipients.push(after.contractorId);

  const unique = Array.from(new Set(recipients.filter(Boolean)));
  await Promise.all(unique.map(uid => admin.firestore().collection('notifications').add({
    userId: uid,
    title,
    body,
    type: 'contract_completed',
    data: { contractId: event.params.contractId },
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  })));
});

// ========================================
// TEMP: TEST NOTIFICATION ENDPOINT (remove after verification)
// ========================================

/**
 * testNotify: Create a sample notification for a given user.
 * Usage: GET/POST with params: uid, title, body, type, secret
 * Security: Requires secret to match TEST_NOTIFY_SECRET (if set). If not set, allows 'dev' as a fallback for quick testing.
 */
export const testNotify = onRequest(async (request, response) => {
  try {
    const expected = process.env.TEST_NOTIFY_SECRET;
    const provided = (request.query.secret || request.headers['x-test-secret'] || '').toString();
    if ((expected && provided !== expected) || (!expected && provided !== 'dev')) {
      response.status(403).json({ error: 'Forbidden' });
      return;
    }

    const uid = (request.method === 'POST' ? (request.body?.uid) : request.query.uid) as string | undefined;
    const title = ((request.method === 'POST' ? (request.body?.title) : request.query.title) as string | undefined) || 'Test Notification';
    const body = ((request.method === 'POST' ? (request.body?.body) : request.query.body) as string | undefined) || 'This is a test.';
    const type = ((request.method === 'POST' ? (request.body?.type) : request.query.type) as string | undefined) || 'test';

    if (!uid) {
      response.status(400).json({ error: 'Missing uid' });
      return;
    }

    const doc = await admin.firestore().collection('notifications').add({
      userId: uid,
      title,
      body,
      type,
      data: {},
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    response.json({ ok: true, id: doc.id });
  } catch (e: any) {
    console.error('testNotify error', e);
    response.status(500).json({ error: e?.message || 'Internal error' });
  }
});

// ========================================
// ADMIN SETUP
// ========================================

/**
 * createAdminUser: One-time setup to create an admin account.
 * Usage: GET/POST with params: email, password, name, secret
 * Security: Requires ADMIN_SETUP_SECRET. Remove or redeploy after use.
 */
export const createAdminUser = onRequest(async (request, response) => {
  try {
    const expected = process.env.ADMIN_SETUP_SECRET;
    const provided = (request.query.secret || request.headers['x-admin-secret'] || '').toString();
    if ((expected && provided !== expected) || (!expected && provided !== 'admin123')) {
      response.status(403).json({ error: 'Forbidden - invalid secret' });
      return;
    }

    const email = ((request.method === 'POST' ? request.body?.email : request.query.email) as string | undefined) || 'admin@jobscaffold.com';
    const password = ((request.method === 'POST' ? request.body?.password : request.query.password) as string | undefined) || 'Admin123!';
    const name = ((request.method === 'POST' ? request.body?.name : request.query.name) as string | undefined) || 'Admin User';

    // Create the user in Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: name,
        emailVerified: true,
      });
    } catch (err: any) {
      // If user already exists, get their UID
      if (err.code === 'auth/email-already-exists') {
        userRecord = await admin.auth().getUserByEmail(email);
      } else {
        throw err;
      }
    }

    // Create/update user document in Firestore with admin privileges
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email,
      name,
      role: 'contractor', // Default to contractor, can switch via admin panel
      isAdmin: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    response.json({
      ok: true,
      uid: userRecord.uid,
      email,
      message: 'Admin user created/updated successfully. Access /admin in the app to switch roles.',
      credentials: {
        email,
        password: '(password set successfully)',
      },
    });
  } catch (e: any) {
    console.error('createAdminUser error', e);
    response.status(500).json({ error: e?.message || 'Internal error' });
  }
});

// ========================================
// LEAD PROCESSING
// ========================================

export const onLeadCreated = onDocumentCreated('leads/{leadId}', async (event) => {
  try {
    const leadData = event.data?.data();
    if (!leadData) return;

    const email = leadData.email;
    const source = leadData.source || 'unknown';
    
    console.log(`New lead captured: ${email} from ${source}`);

    // Send welcome email if SendGrid is configured
    if (sendgridKey && sendgridFrom) {
      try {
        await sgMail.send({
          to: email,
          from: sendgridFrom,
          subject: 'Welcome to JobScaffold!',
          text: `Thanks for your interest in JobScaffold!\n\nWe're building the easiest way for contractors to manage estimates, approvals, scheduling, and payments.\n\nWe'll be in touch soon with early access details.\n\nBest,\nThe JobScaffold Team`,
          html: `
            <h2>Welcome to JobScaffold!</h2>
            <p>Thanks for your interest in JobScaffold!</p>
            <p>We're building the easiest way for contractors to manage estimates, approvals, scheduling, and payments.</p>
            <p>We'll be in touch soon with early access details.</p>
            <p>Best,<br/>The JobScaffold Team</p>
          `,
        });
        console.log(`Welcome email sent to ${email}`);
      } catch (emailError) {
        console.error('Failed to send welcome email:', emailError);
      }
    } else {
      console.log('SendGrid not configured, skipping email');
    }

    // Sync to Mailchimp if configured
    if (mailchimpApiKey && mailchimpListId && mailchimpServerPrefix) {
      try {
        const mailchimpUrl = `https://${mailchimpServerPrefix}.api.mailchimp.com/3.0/lists/${mailchimpListId}/members`;
        const mailchimpData = {
          email_address: email,
          status: 'subscribed',
          merge_fields: {
            SOURCE: source,
          },
          tags: ['website_lead'],
        };
        
        const response = await fetch(mailchimpUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${Buffer.from(`anystring:${mailchimpApiKey}`).toString('base64')}`,
          },
          body: JSON.stringify(mailchimpData),
        });
        
        if (response.ok) {
          console.log(`Lead added to Mailchimp: ${email}`);
        } else {
          const error = await response.text();
          console.error('Mailchimp error:', error);
        }
      } catch (mailchimpError) {
        console.error('Failed to add lead to Mailchimp:', mailchimpError);
      }
    }

    // Send Slack notification if configured
    if (slackWebhookUrl) {
      try {
        await fetch(slackWebhookUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            text: `🎉 New lead captured!`,
            blocks: [
              {
                type: 'section',
                text: {
                  type: 'mrkdwn',
                  text: `*New Lead Captured*\n📧 Email: ${email}\n📍 Source: ${source}`,
                },
              },
            ],
          }),
        });
        console.log('Slack notification sent');
      } catch (slackError) {
        console.error('Failed to send Slack notification:', slackError);
      }
    }

    // Optional: Add to a CRM, mailing list, etc.
    // Example: await addToMailchimp(email);
    
  } catch (error) {
    console.error('Error processing lead:', error);
  }
});

// ========================================
// WEEKLY LEAD SUMMARY
// ========================================

export const weeklyLeadSummary = onSchedule('every monday 09:00', async () => {
  try {
    console.log('Running weekly lead summary...');
    
    // Get leads from the past 7 days
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    
    const snapshot = await admin.firestore()
      .collection('leads')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .orderBy('timestamp', 'desc')
      .get();
    
    const leads = snapshot.docs.map(doc => ({
      email: doc.data().email,
      source: doc.data().source,
      timestamp: doc.data().timestamp?.toDate(),
    }));
    
    const totalLeads = snapshot.size;
    
    if (totalLeads === 0) {
      console.log('No new leads this week');
      return;
    }
    
    // Group by source
    const sourceBreakdown: Record<string, number> = {};
    leads.forEach(lead => {
      const source = lead.source || 'unknown';
      sourceBreakdown[source] = (sourceBreakdown[source] || 0) + 1;
    });
    
    // Build email content
    const leadsList = leads.map(l => 
      `• ${l.email} (${l.source}) - ${l.timestamp?.toLocaleDateString() || 'N/A'}`
    ).join('\n');
    
    const sourceSummary = Object.entries(sourceBreakdown)
      .map(([source, count]) => `• ${source}: ${count}`)
      .join('\n');
    
    const emailText = `Weekly Lead Summary\n\n` +
      `Total new leads this week: ${totalLeads}\n\n` +
      `Breakdown by source:\n${sourceSummary}\n\n` +
      `All leads:\n${leadsList}`;
    
    const emailHtml = `
      <h2>Weekly Lead Summary</h2>
      <p><strong>Total new leads this week:</strong> ${totalLeads}</p>
      <h3>Breakdown by source:</h3>
      <ul>
        ${Object.entries(sourceBreakdown).map(([source, count]) => 
          `<li>${source}: ${count}</li>`
        ).join('')}
      </ul>
      <h3>All leads:</h3>
      <ul>
        ${leads.map(l => 
          `<li>${l.email} (${l.source}) - ${l.timestamp?.toLocaleDateString() || 'N/A'}</li>`
        ).join('')}
      </ul>
    `;
    
    // Send to admin emails if SendGrid is configured
    if (sendgridKey && sendgridFrom && adminEmails.length > 0) {
      for (const adminEmail of adminEmails) {
        try {
          await sgMail.send({
            to: adminEmail.trim(),
            from: sendgridFrom,
            subject: `JobScaffold Weekly Leads: ${totalLeads} new ${totalLeads === 1 ? 'lead' : 'leads'}`,
            text: emailText,
            html: emailHtml,
          });
          console.log(`Weekly summary sent to ${adminEmail}`);
        } catch (emailError) {
          console.error(`Failed to send to ${adminEmail}:`, emailError);
        }
      }
    } else {
      console.log('SendGrid or admin emails not configured, skipping email');
      console.log(emailText);
    }
    
    // Optional: Send to Slack
    if (slackWebhookUrl) {
      try {
        await fetch(slackWebhookUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            text: `📊 Weekly Lead Summary: ${totalLeads} new ${totalLeads === 1 ? 'lead' : 'leads'}`,
            blocks: [
              {
                type: 'section',
                text: {
                  type: 'mrkdwn',
                  text: `*Weekly Lead Summary*\n\n*Total:* ${totalLeads}\n\n*By source:*\n${sourceSummary}`,
                },
              },
            ],
          }),
        });
        console.log('Weekly summary sent to Slack');
      } catch (slackError) {
        console.error('Failed to send weekly summary to Slack:', slackError);
      }
    }
    
  } catch (error) {
    console.error('Error in weekly lead summary:', error);
  }
});

