import SwiftUI

struct LegalView: View {
    let doc: LegalDoc
    
    private let CONTACT_EMAIL = "andersonmourot@aol.com"
    private let APP_NAME = "NextRep"
    private let LAST_UPDATED = "June 2026"
    
    private var title: String {
        TITLES[doc] ?? ""
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Back button
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text("Back")
                                .font(Theme.body(14))
                        }
                        .foregroundColor(Theme.textDim)
                    }
                    
                    // Title and last updated
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(Theme.display(32))
                            .foregroundColor(Theme.text)
                            .tracking(1)
                        
                        Text("Last updated: \(LAST_UPDATED)")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.textDim)
                    }
                    
                    // Document card
                    VStack(alignment: .leading, spacing: 20) {
                        contentView
                    }
                    .padding(20)
                    .background(Theme.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    
                    // Footer
                    Text("\(APP_NAME) · Train with intent.")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private var contentView: some View {
        if doc == .privacy {
            privacyContent
        } else if doc == .terms {
            termsContent
        } else if doc == .disclaimer {
            disclaimerContent
        }
    }
    
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            P("This Privacy Policy explains how \(APP_NAME) (\"we\", \"us\") collects, uses, and protects your information when you use the \(APP_NAME) application and website (the \"Service\"). By using the Service you agree to this policy.")
            
            H("1. Information we collect")
            P("We collect only what's needed to run the Service:")
            UL {
                LI("<B>Account information:</B> your name, email address, and a securely hashed password.")
                LI("<B>App data you create:</B> programs, exercises, workout logs, max-tracker entries, nutrition and hydration entries, body-weight entries, timers, and settings.")
                LI("<B>Basic technical data:</B> standard request information (such as timestamps) needed to operate and secure the Service.")
            }
            P("We do <B>not</B> knowingly collect payment card numbers, government IDs, or sensitive categories of data beyond the fitness information you choose to enter.")
            
            H("2. How we use your information")
            UL {
                LI("To provide, maintain, and improve the Service.")
                LI("To authenticate you and keep your account secure.")
                LI("To send transactional emails such as password resets.")
                LI("To respond to support requests.")
            }
            P("We do not sell your personal information.")
            
            H("3. Email")
            P("We use a third-party email provider to deliver transactional messages (for example, password reset links). Your email address is shared with that provider solely to deliver those messages.")
            
            H("4. Data retention")
            P("We retain your account and app data for as long as your account is active. You may request deletion of your account and associated data at any time (see \"Your rights\").")
            
            H("5. Security")
            P("Passwords are stored as salted hashes, never in plain text, and the Service is served over encrypted connections (HTTPS). No method of transmission or storage is 100% secure, but we take reasonable measures to protect your information.")
            
            H("6. Your rights")
            P("Depending on where you live (for example, under GDPR or CCPA), you may have the right to access, correct, export, or delete your personal data, and to object to certain processing. To exercise these rights, contact us at \(CONTACT_EMAIL).")
            
            H("7. Children")
            P("The Service is not directed to children under 13 (or the minimum age required in your jurisdiction), and we do not knowingly collect their data.")
            
            H("8. Changes")
            P("We may update this policy from time to time. Material changes will be reflected by updating the \"Last updated\" date above.")
            
            H("9. Contact")
            P("Questions about this policy? Email \(CONTACT_EMAIL).")
        }
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            P("These Terms of Service (\"Terms\") govern your access to and use of \(APP_NAME) (the \"Service\"). By creating an account or using the Service, you agree to these Terms.")
            
            H("1. Eligibility & accounts")
            P("You must be at least 13 years old (or the minimum age in your jurisdiction) to use the Service. You are responsible for keeping your login credentials secure and for all activity under your account.")
            
            H("2. Acceptable use")
            P("You agree not to:")
            UL {
                LI("Use the Service for any unlawful purpose or in violation of these Terms.")
                LI("Attempt to gain unauthorized access to the Service or other users' accounts.")
                LI("Interfere with, disrupt, or overload the Service or its infrastructure.")
                LI("Reverse engineer or copy the Service except as permitted by law.")
            }
            
            H("3. Your content")
            P("You retain ownership of the data you create in the Service. You grant us a limited license to store and process that data solely to operate the Service for you.")
            
            H("4. Health & fitness")
            P("The Service provides general fitness and nutrition tracking tools and information. It does not provide medical advice. See the Health & Fitness Disclaimer, which is incorporated into these Terms by reference.")
            
            H("5. Service availability")
            P("The Service is provided on an \"as is\" and \"as available\" basis. We may modify, suspend, or discontinue any part of the Service at any time, and we do not guarantee uninterrupted or error-free operation.")
            
            H("6. Disclaimer of warranties")
            P("To the maximum extent permitted by law, we disclaim all warranties, express or implied, including merchantability, fitness for a particular purpose, and non-infringement.")
            
            H("7. Limitation of liability")
            P("To the maximum extent permitted by law, \(APP_NAME) and its operators will not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, arising from your use of (or inability to use) the Service.")
            
            H("8. Termination")
            P("You may stop using the Service at any time. We may suspend or terminate your access if you violate these Terms.")
            
            H("9. Changes to these Terms")
            P("We may update these Terms from time to time. Continued use of the Service after changes become effective constitutes acceptance of the revised Terms.")
            
            H("10. Contact")
            P("Questions about these Terms? Email \(CONTACT_EMAIL).")
        }
    }
    
    private var disclaimerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            P("<B>Please read this carefully before using \(APP_NAME) for any exercise, training, or nutrition activity.</B>")
            
            H("Not medical advice")
            P("\(APP_NAME) provides general fitness, training, and nutrition information and tracking tools for informational purposes only. It is <B>not</B> a substitute for professional medical advice, diagnosis, or treatment. The Service does not create a doctor-patient, trainer-client, or other professional relationship.")
            
            H("Consult a professional first")
            P("Always consult a qualified physician or healthcare provider before beginning any exercise program, changing your diet, or starting any nutrition or supplementation plan — especially if you are pregnant, have an injury, or have any medical condition. Never disregard professional medical advice or delay seeking it because of something you read or tracked in the Service.")
            
            H("Assumption of risk")
            P("Physical exercise carries inherent risks, including the risk of serious injury. By using \(APP_NAME) and performing any exercises or programs referenced in it, you do so voluntarily and at your own risk. Stop immediately and seek medical attention if you experience pain, dizziness, shortness of breath, or any other symptom.")
            
            H("No guarantee of results")
            P("Individual results vary. \(APP_NAME) makes no guarantee regarding fitness, weight, strength, or health outcomes from using the Service.")
            
            H("Limitation of liability")
            P("To the maximum extent permitted by law, \(APP_NAME) and its operators are not responsible or liable for any injury, loss, or damage of any kind arising from your use of the Service or reliance on any information it provides.")
            
            H("Contact")
            P("Questions? Email \(CONTACT_EMAIL).")
        }
    }
    
    private func H(_ text: String) -> some View {
        Text(text)
            .font(Theme.body(14))
            .fontWeight(.bold)
            .foregroundColor(Theme.text)
            .padding(.top, 8)
    }
    
    private func P(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(parseText(text), id: \.self) { part in
                if part.isBold {
                    Text(part.text)
                        .font(Theme.body(12))
                        .fontWeight(.bold)
                        .foregroundColor(Theme.text)
                } else {
                    Text(part.text)
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                }
            }
        }
    }
    
    private func UL<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
        }
        .padding(.leading, 20)
        .padding(.top, 4)
    }
    
    private func LI(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(Theme.body(12))
                .foregroundColor(Theme.textDim)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(parseText(text), id: \.self) { part in
                    if part.isBold {
                        Text(part.text)
                            .font(Theme.body(12))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.text)
                    } else {
                        Text(part.text)
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                    }
                }
            }
        }
    }
    
    private struct TextPart: Hashable {
        let text: String
        let isBold: Bool
    }
    
    private func parseText(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        var currentText = ""
        var inBold = false
        
        for char in text {
            if char == "<" {
                if !currentText.isEmpty {
                    parts.append(TextPart(text: currentText, isBold: inBold))
                    currentText = ""
                }
            } else if char == ">" {
                if currentText == "B" {
                    inBold = true
                } else if currentText == "/B" {
                    inBold = false
                }
                currentText = ""
            } else {
                currentText.append(char)
            }
        }
        
        if !currentText.isEmpty {
            parts.append(TextPart(text: currentText, isBold: inBold))
        }
        
        return parts
    }
}

enum LegalDoc {
    case privacy
    case terms
    case disclaimer
}

private let TITLES: [LegalDoc: String] = [
    .privacy: "Privacy Policy",
    .terms: "Terms of Service",
    .disclaimer: "Health & Fitness Disclaimer"
]