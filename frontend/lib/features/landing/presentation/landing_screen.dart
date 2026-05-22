import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // =========================================================
              // HERO SECTION
              // =========================================================

              Material(
                child: _buildHeroSection(context, theme),
              ),

              // =========================================================
              // MAIN CONTENT
              // =========================================================

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 60,
                    ),
                    child: Column(
                      children: [
                        _buildFeaturesSection(theme),

                        const SizedBox(height: 100),

                        _buildMissionSection(theme),

                        const SizedBox(height: 100),

                        _buildFAQSection(theme),

                        const SizedBox(height: 100),

                        _buildCTASection(context, theme),

                        const SizedBox(height: 80),

                        const _AppFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HERO SECTION
  // =========================================================

  Widget _buildHeroSection(
    BuildContext context,
    ThemeData theme,
  ) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.92,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/hero.png',
            fit: BoxFit.cover,
          ),

          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Decorative Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 16,
                    sigmaY: 16,
                  ),
                  child: Container(
                    width: 760,
                    padding: const EdgeInsets.all(42),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Addis Ababa, Ethiopia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Main Heading
                        Text(
                          'Education starts\nfrom the right choice.',
                          textAlign: TextAlign.center,
                          style:
                              theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Amharic Subtitle
                        Text(
                          'ትምህርት በትክክለኛው ምርጫ ይጀምራል።',
                          textAlign: TextAlign.center,
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 580),
                          child: Text(
                            'A modern platform helping Ethiopian families discover, compare, and choose schools that truly fit their child’s needs, aspirations, and future.',
                            textAlign: TextAlign.center,
                            style:
                                theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  Colors.white.withOpacity(0.85),
                              height: 1.7,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Buttons
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            FilledButton.icon(
                              onPressed: () =>
                                  context.go('/register'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 20,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              icon: const Text(
                                'Start Exploring',
                              ),
                              label: const Icon(
                                Icons.arrow_forward,
                                size: 18,
                              ),
                            ),

                            OutlinedButton(
                              onPressed: () =>
                                  context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 20,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FEATURES SECTION
  // =========================================================

  Widget _buildFeaturesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR SERVICES',
          style:
              theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        const SizedBox(height: 16),

        Text(
          'Empowering education through connected communities.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 40),

        GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4, // Number of features
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500, // Maximum width of a single card
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          mainAxisExtent: 220, // Forces a healthy, static height instead of a shrinking ratio
        ),
        itemBuilder: (context, index) {
          // Put your list of card data here and map it
          final features = [
            _featureCard(theme, Icons.auto_awesome_outlined, 'School Recommendations', 'Tailored school suggestions based on your child’s academic and personal needs.'),
            _featureCard(theme, Icons.location_searching_outlined, 'Smart Discovery', 'Compare schools by curriculum, facilities, tuition, and location.'),
            _featureCard(theme, Icons.groups_outlined, 'Parent Engagement', 'Strengthening communication between schools and families.'),
            _featureCard(theme, Icons.trending_up_outlined, 'Educational Insights', 'Helping schools and parents make more informed decisions.'),
          ];
          return features[index];
        },
      ),
    ],
  );
}
     

  Widget _featureCard(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.primary,
          ),

          const Spacer(),

          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MISSION SECTION
  // =========================================================

  Widget _buildMissionSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            'MISSION',
            style:
                theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
          ),

          const SizedBox(height: 18),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Our mission is to democratize access to quality education information across Ethiopia. Every child deserves a school that nurtures their potential, and every family deserves the tools to find it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FAQ SECTION
  // =========================================================

  Widget _buildFAQSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMON QUESTIONS',
          style:
              theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        const SizedBox(height: 16),

        Text(
          'Answers to get you started.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 32),

        _faqItem(
          theme,
          'Is the system free for parents?',
          'Yes. Parents can create accounts and explore schools for free.',
        ),

        _faqItem(
          theme,
          'Which cities are covered?',
          'We are currently focused on Addis Ababa and expanding gradually.',
        ),

        _faqItem(
          theme,
          'How are schools verified?',
          'Each school profile is reviewed before publication to ensure accuracy.',
        ),

        _faqItem(
          theme,
          'How do recommendations work?',
          'We match schools using curriculum, facilities, location, and budget preferences.',
        ),
      ],
    );
  }

  Widget _faqItem(
    ThemeData theme,
    String question,
    String answer,
  ) {
    return SizedBox(
  width: double.infinity,
  child: Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    )
    );
  }

  // =========================================================
  // CTA SECTION
  // =========================================================

  Widget _buildCTASection(
    BuildContext context,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Column(
        children: [
          Text(
            'Ready to find the right school?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Create your account and begin exploring schools tailored to your child.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: () => context.go('/register'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              shape: const StadiumBorder(),
            ),
            child: const Text('Create Your Account'),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// FOOTER
// =========================================================

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const Divider(height: 64),

        Text(
          '© ${DateTime.now().year} School Recommendation System',
          style: theme.textTheme.bodySmall,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}