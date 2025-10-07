import 'package:flutter/material.dart';

import '../theme/theme_colours.dart';

class LegalInformationPage extends StatefulWidget {
  const LegalInformationPage({super.key});

  @override
  State<LegalInformationPage> createState() => _LegalInformationPageState();
}

class _LegalInformationPageState extends State<LegalInformationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args < 2) {
      _tabController.index = args;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Legal Information',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: kMainColour,
              indicatorWeight: 3,
              labelColor: kMainColour,
              unselectedLabelColor:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              isScrollable: isLandscape,
              tabAlignment:
                  isLandscape ? TabAlignment.center : TabAlignment.fill,
              tabs: const [
                Tab(text: 'Terms & Conditions'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _wrapForLandscape(_buildTermsAndConditions()),
          _wrapForLandscape(_buildPrivacyPolicy()),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentHeader(
            'Terms and Conditions',
            'Last updated: December 2024',
            Icons.article,
          ),
          const SizedBox(height: 24),
          _buildIntroCard(),
          const SizedBox(height: 24),
          _buildLegalSection(
            '1. Company Information',
            Icons.business_outlined,
            _buildCompanyInfo(),
          ),
          _buildLegalSection(
            '2. Products and Services',
            Icons.inventory_2_outlined,
            _buildProductsInfo(),
          ),
          _buildLegalSection(
            '3. Orders and Payment',
            Icons.payment_outlined,
            _buildPaymentInfo(),
          ),
          _buildLegalSection(
            '4. Shipping and Delivery',
            Icons.local_shipping_outlined,
            _buildShippingInfo(),
          ),
          _buildLegalSection(
            '5. Returns and Refunds',
            Icons.assignment_return_outlined,
            _buildReturnsInfo(),
          ),
          _buildLegalSection(
            '6. User Responsibilities',
            Icons.person_outline,
            _buildUserResponsibilities(),
          ),
          _buildLegalSection(
            '7. Limitation of Liability',
            Icons.shield_outlined,
            _buildLiabilityInfo(),
          ),
          _buildLegalSection(
            '8. Governing Law',
            Icons.gavel_outlined,
            _buildGoverningLaw(),
          ),
          _buildContactCard(),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentHeader(
            'Privacy Policy',
            'Last updated: December 2024',
            Icons.privacy_tip,
          ),
          const SizedBox(height: 24),
          _buildPrivacyIntroCard(),
          const SizedBox(height: 24),
          _buildLegalSection(
            '1. Information We Collect',
            Icons.info_outline,
            _buildInfoCollection(),
          ),
          _buildLegalSection(
            '2. How We Use Your Information',
            Icons.how_to_reg_outlined,
            _buildInfoUsage(),
          ),
          _buildLegalSection(
            '3. Information Sharing',
            Icons.share_outlined,
            _buildInfoSharing(),
          ),
          _buildLegalSection(
            '4. Data Security',
            Icons.security_outlined,
            _buildDataSecurity(),
          ),
          _buildLegalSection(
            '5. Your Privacy Rights',
            Icons.verified_user_outlined,
            _buildPrivacyRights(),
          ),
          _buildLegalSection(
            '6. Data Retention',
            Icons.schedule_outlined,
            _buildDataRetention(),
          ),
          _buildLegalSection(
            '7. Children\'s Privacy',
            Icons.child_care_outlined,
            _buildChildrenPrivacy(),
          ),
          _buildLegalSection(
            '8. Policy Updates',
            Icons.update_outlined,
            _buildPolicyUpdates(),
          ),
          _buildContactCard(),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader(String title, String subtitle, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColour.withOpacity(0.1), kMainColour.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kMainColour.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kMainColour.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: kMainColour),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isDark
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to ByteCart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kMainColour,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'By accessing or using the ByteCart mobile application, you agree to be bound by these Terms and Conditions. Please read them carefully before using our services.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyIntroCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isDark
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Commitment to Privacy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kMainColour,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ByteCart respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our services.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, IconData icon, Widget content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            expansionTileTheme: ExpansionTileThemeData(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              iconColor: kMainColour,
              collapsedIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            child: ExpansionTile(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                  child: content,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String content, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = color ?? (isDark ? Colors.white : Colors.black87);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
      fontSize: 16,
    );
    final cellStyle = TextStyle(
      fontSize: 14,
      color: isDark ? Colors.grey[300] : Colors.grey[800],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Hours', style: labelStyle),
          const SizedBox(height: 6),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Monday - Friday', style: cellStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '9:00 AM - 6:00 PM',
                      textAlign: TextAlign.right,
                      style: cellStyle,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Saturday', style: cellStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '9:00 AM - 5:00 PM',
                      textAlign: TextAlign.right,
                      style: cellStyle,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Sunday', style: cellStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Closed',
                      textAlign: TextAlign.right,
                      style: cellStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.white70 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildContactItem(
            Icons.email_outlined,
            'Email',
            'bytecart@gmail.com',
            textColor: textColor,
            labelColor: labelColor,
          ),
          _buildContactItem(
            Icons.phone_outlined,
            'Phone',
            '+94 76 123 4567',
            textColor: textColor,
            labelColor: labelColor,
          ),
          _buildContactItem(
            Icons.location_on_outlined,
            'Address',
            '45, Lake View Road, Nugegoda, Sri Lanka',
            textColor: textColor,
            labelColor: labelColor,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.grey[200]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'For questions about these terms or privacy practices, please contact us using any of the methods above. We\'re here to help!',
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value, {
    Color? textColor,
    Color? labelColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor ?? Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor ?? Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox('Company Details', '''ByteCart Electronic Store
📍 45, Lake View Road, Nugegoda, Sri Lanka
📧 bytecart@gmail.com
📞 +94 76 123 4567'''),
        _buildBusinessHoursBox(),
      ],
    );
  }

  Widget _buildProductsInfo() {
    return _buildInfoBox(
      '',
      '''• ByteCart specializes in electronics and accessories
• All products are genuine and come with manufacturer warranties
• Product availability is subject to stock levels
• Prices are in US Dollars (USD) and may change without prior notice
• Product images are for illustration purposes only
• Specifications may vary slightly from images shown''',
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      children: [
        _buildInfoBox(
          'Accepted Payment Methods',
          '''• Visa and MasterCard (secure processing)
• Mintpay (with flexible installment options)
• Koko (with convenient installment plans)
• Cash on Delivery (COD) - subject to conditions''',
        ),
        _buildInfoBox(
          'Order Terms',
          '''• All orders are subject to acceptance and availability
• We reserve the right to refuse or cancel any order
• Payment must be completed before order processing begins
• COD orders may require advance payment for high-value items (>LKR 50,000)
• Order confirmation will be sent via SMS and email''',
        ),
      ],
    );
  }

  Widget _buildShippingInfo() {
    return Column(
      children: [
        _buildInfoBox(
          'Delivery Coverage',
          '''• Delivery available within Sri Lanka only
• Estimated delivery times: 1-3 business days (Colombo area)
• Estimated delivery times: 2-5 business days (other areas)
• Shipping costs calculated based on location and order value
• Free shipping available for orders above LKR 15,000''',
        ),
        _buildInfoBox(
          'Important Notice',
          '''ByteCart is not liable for delays caused by:
• Courier service operational issues
• Adverse weather conditions
• Natural disasters or emergencies
• Government restrictions or lockdowns
• Other unforeseeable circumstances beyond our control''',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildReturnsInfo() {
    return Column(
      children: [
        _buildInfoBox(
          'Defective Products',
          '''• Report defects within 7 days of delivery
• Provide clear photos and detailed description of the defect
• ByteCart will verify the claim within 2 business days
• Return shipping costs covered by ByteCart for confirmed defects
• Refunds processed to original payment method within 7-14 business days''',
          color: Colors.green,
        ),
        _buildInfoBox(
          'Non-Defective Returns',
          '''• Returns accepted within 48 hours of delivery
• Products must be unopened and in original packaging
• All accessories and documentation must be included
• Customer bears return shipping costs
• 15% restocking fee may apply to certain categories''',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildUserResponsibilities() {
    return Column(
      children: [
        _buildInfoBox(
          'Account Requirements',
          '''• Must be 18 years or older to create an account
• Provide accurate and complete information
• Keep login credentials secure and confidential
• One account per person - duplicate accounts will be merged or removed
• Notify us immediately of any unauthorized account access''',
        ),
        _buildInfoBox(
          'Prohibited Activities',
          '''• Providing false or misleading information
• Placing fraudulent or fictitious orders
• Reselling products for commercial purposes without authorization
• Misusing or attempting to damage the app or website
• Violating any applicable laws or regulations
• Harassment of staff or other customers''',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildLiabilityInfo() {
    return _buildInfoBox(
      'Limitation of Liability',
      '''ByteCart's liability is limited and we are not responsible for:
• Misuse of products by customers after purchase
• Damage caused by improper installation, handling, or use
• Compatibility issues with customer devices or systems
• Loss of data, profits, or business opportunities
• Indirect, incidental, or consequential damages
• Damages exceeding the purchase price of the specific product

Maximum liability is limited to the original purchase price of the product in question.''',
      color: Colors.orange,
    );
  }

  Widget _buildGoverningLaw() {
    return _buildInfoBox(
      '',
      '''These Terms and Conditions are governed by and construed in accordance with the laws of Sri Lanka. Any disputes arising from or relating to these terms or your use of our services will be resolved exclusively in the courts of Sri Lanka. By using our services, you agree to submit to the exclusive jurisdiction of Sri Lankan courts and waive any objection to venue or inconvenient forum.''',
    );
  }

  Widget _buildInfoCollection() {
    return Column(
      children: [
        _buildInfoBox(
          'Personal Information',
          '''• Full name, email address, and phone number
• Billing and shipping addresses
• Date of birth (for age verification purposes)
• Payment information (securely processed by certified providers)''',
        ),
        _buildInfoBox(
          'Technical Information',
          '''• Device information and operating system details
• App usage patterns, preferences, and behavior
• IP address and approximate location data
          • Cookies and similar tracking technologies
• Performance and crash reports''',
        ),
        _buildInfoBox(
          'Transaction Information',
          '''• Complete order history and product preferences
• Payment and delivery details and status
• Customer service interactions and support tickets
• Reviews and ratings provided by you''',
        ),
      ],
    );
  }

  Widget _buildInfoUsage() {
    return _buildInfoBox(
      'We use your information to:',
      '''• Process, fulfill, and track your orders efficiently
• Communicate about orders, deliveries, and account updates
• Provide responsive customer support and technical assistance
• Send promotional offers and updates (with your explicit consent)
• Improve our products, services, and user experience
• Prevent fraud, enhance security, and protect our users
• Comply with legal obligations and regulatory requirements
• Analyze app usage patterns and performance metrics
• Personalize your shopping experience and recommendations''',
    );
  }

  Widget _buildInfoSharing() {
    return Column(
      children: [
        _buildInfoBox(
          'Trusted Partners',
          '''We may share your information with:
• Courier and logistics services for delivery purposes
• Payment processors for secure transaction processing
• Technology providers for app functionality and maintenance
• Analytics services for performance improvement (anonymized data only)''',
          color: Colors.blue,
        ),
        _buildInfoBox('Legal Requirements', '''Information may be shared when:
• Required by law, court order, or legal process
• Necessary to protect our rights, property, or safety
• Needed to prevent fraud or illegal activities
• Required for regulatory compliance''', color: Colors.orange),
        _buildInfoBox(
          'What We DON\'T Do',
          '''• We do NOT sell your personal information to third parties
• We do NOT share data for marketing purposes without consent
• We do NOT transfer data outside Sri Lanka without adequate protection
• We do NOT access your device storage without permission''',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildDataSecurity() {
    return Column(
      children: [
        _buildInfoBox(
          'Our Security Measures',
          '''• End-to-end encryption of sensitive data in transit and storage
• Secure payment processing through certified, PCI-compliant providers
• Regular security audits, penetration testing, and system updates
• Strict access controls and comprehensive employee training
• Secure data centers with redundant backup systems
• Multi-factor authentication for administrative access''',
        ),
        _buildInfoBox(
          'Your Security Responsibilities',
          '''• Keep your account credentials confidential and secure
• Use strong, unique passwords and update them regularly
• Always log out from shared or public devices
• Report suspicious activities or security concerns immediately
• Keep your app updated to the latest version
• Be cautious when using public Wi-Fi networks''',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildPrivacyRights() {
    return _buildInfoBox(
      'Under Sri Lankan data protection laws, you have the right to:',
      '''• Access and review your personal information
• Correct inaccurate or incomplete data
• Request deletion of your data (subject to legal retention requirements)
• Opt-out of marketing communications at any time
• Withdraw consent for data processing (where consent is the legal basis)
• Request data portability in a structured format
• File a complaint with relevant data protection authorities
• Receive information about data breaches that may affect you

To exercise these rights, please contact us at bytecart@gmail.com with your request and proof of identity.''',
    );
  }

  Widget _buildDataRetention() {
    return Column(
      children: [
        _buildInfoBox(
          'Retention Periods',
          '''• Active accounts: Data retained while your account remains active
• Transaction records: 7 years for tax compliance and legal requirements
• Marketing data: Until you opt-out or withdraw consent
• Technical logs: Up to 2 years for security analysis and system improvement
• Support tickets: 3 years for quality assurance and training purposes''',
        ),
        _buildInfoBox(
          'Data Deletion',
          '''When you request account deletion or data is no longer needed:
• Personal data is permanently removed from active systems within 30 days
• Some information may be retained in encrypted backups for up to 1 year
• Legal and regulatory records are retained as required by law
• Anonymized data may be retained for statistical and analytical purposes''',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildChildrenPrivacy() {
    return _buildInfoBox(
      '',
      '''ByteCart is intended for users who are 18 years of age or older. We do not knowingly collect, use, or disclose personal information from children under 18 years of age.

If we become aware that we have inadvertently collected personal information from a child under 18, we will:
• Delete the information immediately from our systems
• Terminate the associated account
• Notify the parent or guardian if contact information is available
• Take steps to prevent future collection from that individual

Parents or guardians who believe their child has provided information to us should contact us immediately at bytecart@gmail.com.''',
      color: Colors.orange,
    );
  }

  Widget _buildPolicyUpdates() {
    return Column(
      children: [
        _buildInfoBox(
          'When We Update This Policy',
          '''We may update this Privacy Policy periodically to reflect:
• Changes in our business practices and services
• New legal or regulatory requirements
• Advances in technology and security standards
• Feedback from users and stakeholders''',
        ),
        _buildInfoBox(
          'How We Notify You',
          '''Significant changes will be communicated through:
• Push notifications within the app
• Email notifications to your registered address
• Prominent notices on our app homepage
• SMS alerts for major policy changes (with 30 days advance notice)

Continued use of our services after updates constitutes acceptance of the revised policy.''',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _wrapForLandscape(Widget child) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (!isLandscape) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );
  }
}
