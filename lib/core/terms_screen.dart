// lib/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kEulaVersionKey = 'eula_version';
const int kCurrentEulaVersion = 1;

class TermsScreen extends StatelessWidget {
  final VoidCallback onAgreed;
  TermsScreen({required this.onAgreed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terms & Community Guidelines')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Expanded(child: SingleChildScrollView(child: Text(_eulaText))),
          ElevatedButton(
            child: Text('I Agree'),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(kEulaVersionKey, kCurrentEulaVersion);
              onAgreed();
            },
          )
        ]),
      ),
    );
  }

  String get _eulaText => '''
  End User License Agreement (EULA) for Xabe
Version 1.0
Effective Date: May 8, 2025

1. Acceptance of Terms
By downloading, installing, or using Xabe (the “App”), you (“User”) agree to be bound by this End User License Agreement (“EULA”). If you do not agree to these terms, do not use the App.

2. Definitions
“User-Generated Content” means any text, images, video, audio, or other materials that Users submit, post, upload, or otherwise make available via the App.

“Objectionable Content” includes, but is not limited to, hate speech, harassment, threats, pornography, graphic violence, illegal activity, or any content that violates applicable law or these terms.

“Moderator” means a person or team authorized by Xabe to review and remove User-Generated Content.

3. License Grant
Subject to your compliance with this EULA, Xabe grants you a limited, non-exclusive, non-transferable, revocable license to use the App on devices you own or control.

4. User Obligations
Compliance with Laws & Policies. You must comply with all applicable laws and Xabe’s Community Guidelines.

Accurate Information. You represent that any information you provide (e.g. account registration) is true and accurate.

No Misuse. You will not reverse-engineer the App, attempt to access unauthorized systems, or interfere with other Users’ access.

5. Content Standards & Prohibitions
You agree not to submit or share any Objectionable Content. Examples include, but are not limited to:

Hate speech or symbols targeting protected groups

Harassing, threatening, or demeaning language

Adult sexual content or pornography

Graphic violence or encouragement thereof

Promotion of criminal or self-harm behavior

Spam, phishing, or deceptive solicitations

6. Moderation & Enforcement
Automated Screening. All submissions are subject to automated moderation filters. Content flagged as high-risk will be blocked or held for review.

User Flagging. Users may flag content for review by selecting a reason (e.g. Harassment, Hate, Spam).

Blocking. Users may block other Users; blocked accounts cannot view or interact with each other’s content.

24-Hour Review SLA. Within 24 hours of a flag or automated block, our moderation team will review and take one of the following actions:

Remove Content & Suspend User. If content violates this EULA, it will be permanently removed and the offending account suspended or banned.

Restore Content. If the review finds no violation, content will be restored and the flag dismissed.

Action Logs. Every moderation decision is logged (Moderator ID, date/time, action taken) for audit.

7. Reporting & Appeals
If your content is removed or your account suspended, you may submit an appeal via our in-App support form within 7 days.

Appeals will be reviewed by a separate moderator within 48 hours.

8. Termination
We may suspend or terminate your access immediately if you breach this EULA, without refund. Upon termination, all licenses granted hereunder terminate, and you must cease all use of the App.

9. Intellectual Property
All App content, trademarks, logos, and software are our property or licensed to us. This EULA does not transfer any ownership rights in the App or its content.

10. Privacy
Your use of the App is also governed by our Privacy Policy, which explains how we collect, use, and share your personal data. By using the App, you consent to that policy.

11. Disclaimers & Limitation of Liability
No Warranty. The App is provided “as is” without warranty of any kind.

Limitation of Liability. To the fullest extent permitted by law, Xabe’s liability is limited to direct damages up to the amount you paid for the App (if any). We are not liable for consequential, incidental, or punitive damages.

12. Changes to This EULA
We may update this EULA from time to time. When we do, we’ll post the new version with an updated “Effective Date.” Continued use of the App after that date constitutes acceptance of the revised EULA.

Contact Us
If you have questions or concerns about this EULA or need to appeal a moderation decision, please contact nubiarabo1@gmail.com.
  ''';
}
