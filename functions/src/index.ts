import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import Stripe from 'stripe';

admin.initializeApp();

// Read Stripe key from runtime config: functions:config:set stripe.secret=sk_test_...
const stripeSecret = process.env.STRIPE_SECRET || (functions.config().stripe && functions.config().stripe.secret);
if (!stripeSecret) {
  console.warn('Stripe secret not set. Set STRIPE_SECRET env or functions config stripe.secret');
}
const stripe = new Stripe(stripeSecret || 'sk_test_missing', { apiVersion: '2024-06-20' });

// ========================================
// PAYMENT FUNCTIONS
// ========================================

export const createCheckoutSession = functions.https.onCall(async (data, context) => {
  try {
    // Enforce auth (recommended)
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

    const amount = Number(data?.amount);
    const currency = (data?.currency || 'usd').toString();
    const title = (data?.title || 'Invoice').toString();
    const description = (data?.description || '').toString();
    const invoiceId = (data?.invoiceId || '').toString();
    const userId = context.auth.uid;

    if (!amount || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Amount must be a positive integer in the smallest currency unit');
    }

    const successUrl = data?.successUrl || 'https://project-bridge-cm.web.app/payments/success';
    const cancelUrl = data?.cancelUrl || 'https://project-bridge-cm.web.app/payments/cancel';

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
    if (err instanceof functions.https.HttpsError) throw err;
    throw new functions.https.HttpsError('internal', err?.message || 'Unknown error');
  }
});

// Webhook to mark invoices paid. For full security, set STRIPE_WEBHOOK_SECRET and verify signatures.
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || (functions.config().stripe && functions.config().stripe.webhook);
    let event: Stripe.Event;

    // If secret is configured, verify signature. Otherwise, accept raw JSON (not recommended for production).
    if (webhookSecret && req.headers['stripe-signature']) {
      const sig = req.headers['stripe-signature'] as string;
      const rawBody = (req as any).rawBody || Buffer.from(JSON.stringify(req.body));
      event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
    } else {
      event = req.body as Stripe.Event;
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

    res.json({ received: true });
  } catch (e: any) {
    console.error('stripeWebhook error', e);
    res.status(400).send('Webhook error');
  }
});

// ========================================
// NOTIFICATION FUNCTIONS
// ========================================

/**
 * Send notification when a new project update is posted
 */
export const onProjectUpdate = functions.firestore
  .document('updates/{updateId}')
  .onCreate(async (snap, context) => {
    const update = snap.data();
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
          updateId: context.params.updateId,
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
export const onFileUpload = functions.firestore
  .document('files/{fileId}')
  .onCreate(async (snap, context) => {
    const file = snap.data();
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
          fileId: context.params.fileId,
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
export const onInvoiceCreated = functions.firestore
  .document('invoices/{invoiceId}')
  .onCreate(async (snap, context) => {
    const invoice = snap.data();
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
          invoiceId: context.params.invoiceId,
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
export const onNewMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
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
          messageId: context.params.messageId,
          senderId: senderId,
          type: 'message',
        },
      });

      console.log('Message notification sent');
    } catch (error) {
      console.error('Error sending message notification:', error);
    }
  });
