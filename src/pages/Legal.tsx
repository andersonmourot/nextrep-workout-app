import { ArrowLeft } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

// Contact address shown in the legal documents. Change this to your support
// address if you'd rather not use a personal inbox.
const CONTACT_EMAIL = 'andersonmourot@aol.com'
const APP_NAME = 'NextRep'
const LAST_UPDATED = 'June 2026'

type LegalDoc = 'privacy' | 'terms' | 'disclaimer'

const TITLES: Record<LegalDoc, string> = {
  privacy: 'Privacy Policy',
  terms: 'Terms of Service',
  disclaimer: 'Health & Fitness Disclaimer',
}

function Privacy() {
  return (
    <>
      <P>
        This Privacy Policy explains how {APP_NAME} ("we", "us") collects, uses, and protects your
        information when you use the {APP_NAME} application and website (the "Service"). By using the
        Service you agree to this policy.
      </P>
      <H>1. Information we collect</H>
      <P>We collect only what's needed to run the Service:</P>
      <UL>
        <LI>
          <B>Account information:</B> your name, email address, and a securely hashed password.
        </LI>
        <LI>
          <B>App data you create:</B> programs, exercises, workout logs, max-tracker entries,
          nutrition and hydration entries, body-weight entries, timers, and settings.
        </LI>
        <LI>
          <B>Basic technical data:</B> standard request information (such as timestamps) needed to
          operate and secure the Service.
        </LI>
      </UL>
      <P>
        We do <B>not</B> knowingly collect payment card numbers, government IDs, or sensitive
        categories of data beyond the fitness information you choose to enter.
      </P>
      <H>2. How we use your information</H>
      <UL>
        <LI>To provide, maintain, and improve the Service.</LI>
        <LI>To authenticate you and keep your account secure.</LI>
        <LI>To send transactional emails such as password resets.</LI>
        <LI>To respond to support requests.</LI>
      </UL>
      <P>We do not sell your personal information.</P>
      <H>3. Email</H>
      <P>
        We use a third-party email provider to deliver transactional messages (for example, password
        reset links). Your email address is shared with that provider solely to deliver those
        messages.
      </P>
      <H>4. Data retention</H>
      <P>
        We retain your account and app data for as long as your account is active. You may request
        deletion of your account and associated data at any time (see "Your rights"). In the native
        iOS app, you can also initiate permanent account deletion directly from Settings &gt; Account
        &gt; Delete Account.
      </P>
      <H>5. Security</H>
      <P>
        Passwords are stored as salted hashes, never in plain text, and the Service is served over
        encrypted connections (HTTPS). No method of transmission or storage is 100% secure, but we
        take reasonable measures to protect your information.
      </P>
      <H>6. Your rights</H>
      <P>
        Depending on where you live (for example, under GDPR or CCPA), you may have the right to
        access, correct, export, or delete your personal data, and to object to certain processing.
        To exercise these rights, contact us at {CONTACT_EMAIL}.
      </P>
      <H>7. Children</H>
      <P>
        The Service is not directed to children under 13 (or the minimum age required in your
        jurisdiction), and we do not knowingly collect their data.
      </P>
      <H>8. Changes</H>
      <P>
        We may update this policy from time to time. Material changes will be reflected by updating
        the "Last updated" date above.
      </P>
      <H>9. Contact</H>
      <P>Questions about this policy? Email {CONTACT_EMAIL}.</P>
    </>
  )
}

function Terms() {
  return (
    <>
      <P>
        These Terms of Service ("Terms") govern your access to and use of {APP_NAME} (the "Service").
        By creating an account or using the Service, you agree to these Terms.
      </P>
      <H>1. Eligibility & accounts</H>
      <P>
        You must be at least 13 years old (or the minimum age in your jurisdiction) to use the
        Service. You are responsible for keeping your login credentials secure and for all activity
        under your account.
      </P>
      <H>2. Acceptable use</H>
      <P>You agree not to:</P>
      <UL>
        <LI>Use the Service for any unlawful purpose or in violation of these Terms.</LI>
        <LI>Attempt to gain unauthorized access to the Service or other users' accounts.</LI>
        <LI>Interfere with, disrupt, or overload the Service or its infrastructure.</LI>
        <LI>Reverse engineer or copy the Service except as permitted by law.</LI>
      </UL>
      <H>3. Your content</H>
      <P>
        You retain ownership of the data you create in the Service. You grant us a limited license to
        store and process that data solely to operate the Service for you.
      </P>
      <H>4. Health & fitness</H>
      <P>
        The Service provides general fitness and nutrition tracking tools and information. It does
        not provide medical advice. See the Health & Fitness Disclaimer, which is incorporated into
        these Terms by reference.
      </P>
      <H>5. Service availability</H>
      <P>
        The Service is provided on an "as is" and "as available" basis. We may modify, suspend, or
        discontinue any part of the Service at any time, and we do not guarantee uninterrupted or
        error-free operation.
      </P>
      <H>6. Disclaimer of warranties</H>
      <P>
        To the maximum extent permitted by law, we disclaim all warranties, express or implied,
        including merchantability, fitness for a particular purpose, and non-infringement.
      </P>
      <H>7. Limitation of liability</H>
      <P>
        To the maximum extent permitted by law, {APP_NAME} and its operators will not be liable for
        any indirect, incidental, special, consequential, or punitive damages, or any loss of data,
        arising from your use of (or inability to use) the Service.
      </P>
      <H>8. Termination</H>
      <P>
        You may stop using the Service at any time. We may suspend or terminate your access if you
        violate these Terms.
      </P>
      <H>9. Changes to these Terms</H>
      <P>
        We may update these Terms from time to time. Continued use of the Service after changes
        become effective constitutes acceptance of the revised Terms.
      </P>
      <H>10. Contact</H>
      <P>Questions about these Terms? Email {CONTACT_EMAIL}.</P>
    </>
  )
}

function Disclaimer() {
  return (
    <>
      <P>
        <B>
          Please read this carefully before using {APP_NAME} for any exercise, training, or nutrition
          activity.
        </B>
      </P>
      <H>Not medical advice</H>
      <P>
        {APP_NAME} provides general fitness, training, and nutrition information and tracking tools
        for informational purposes only. It is <B>not</B> a substitute for professional medical
        advice, diagnosis, or treatment. The Service does not create a doctor-patient, trainer-client,
        or other professional relationship.
      </P>
      <H>Consult a professional first</H>
      <P>
        Always consult a qualified physician or healthcare provider before beginning any exercise
        program, changing your diet, or starting any nutrition or supplementation plan — especially
        if you are pregnant, have an injury, or have any medical condition. Never disregard
        professional medical advice or delay seeking it because of something you read or tracked in
        the Service.
      </P>
      <H>Assumption of risk</H>
      <P>
        Physical exercise carries inherent risks, including the risk of serious injury. By using{' '}
        {APP_NAME} and performing any exercises or programs referenced in it, you do so voluntarily
        and at your own risk. Stop immediately and seek medical attention if you experience pain,
        dizziness, shortness of breath, or any other symptom.
      </P>
      <H>No guarantee of results</H>
      <P>
        Individual results vary. {APP_NAME} makes no guarantee regarding fitness, weight, strength, or
        health outcomes from using the Service.
      </P>
      <H>Limitation of liability</H>
      <P>
        To the maximum extent permitted by law, {APP_NAME} and its operators are not responsible or
        liable for any injury, loss, or damage of any kind arising from your use of the Service or
        reliance on any information it provides.
      </P>
      <H>Contact</H>
      <P>Questions? Email {CONTACT_EMAIL}.</P>
    </>
  )
}

function H({ children }: { children: React.ReactNode }) {
  return <h2 className="heading mt-6 text-lg font-bold text-zinc-100">{children}</h2>
}
function P({ children }: { children: React.ReactNode }) {
  return <p className="mt-3 text-sm leading-relaxed text-zinc-400">{children}</p>
}
function UL({ children }: { children: React.ReactNode }) {
  return <ul className="mt-3 list-disc space-y-1.5 pl-5 text-sm leading-relaxed text-zinc-400">{children}</ul>
}
function LI({ children }: { children: React.ReactNode }) {
  return <li>{children}</li>
}
function B({ children }: { children: React.ReactNode }) {
  return <span className="font-semibold text-zinc-200">{children}</span>
}

export function Legal({ doc }: { doc: LegalDoc }) {
  const navigate = useNavigate()
  return (
    <div className="container-app animate-fade-in space-y-4 py-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">{TITLES[doc]}</h1>
        <p className="mt-1 text-xs text-zinc-600">Last updated: {LAST_UPDATED}</p>
      </div>

      <section className="card p-5">
        {doc === 'privacy' && <Privacy />}
        {doc === 'terms' && <Terms />}
        {doc === 'disclaimer' && <Disclaimer />}
      </section>

      <p className="pb-2 text-center text-xs text-zinc-600">{APP_NAME} · Train with intent.</p>
    </div>
  )
}
