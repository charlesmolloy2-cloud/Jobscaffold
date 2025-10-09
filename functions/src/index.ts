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

    const successUrl = data?.successUrl || 'https://your-host.example.com/payments/success';
    const cancelUrl = data?.cancelUrl || 'https://your-host.example.com/payments/cancel';

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
    res.status(400).send(`Webhook Error: ${e.message || e}`);
  }
});
