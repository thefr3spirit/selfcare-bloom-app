import '../models/recommendation.dart';

/// A single external source backing a piece of health/wellness content shown
/// in the app. Used to satisfy App Store Guideline 1.4.1 (medical apps must
/// cite sources for health information).
class Citation {
  final String id;
  final String label; // Short name shown inline, e.g. "Cohen et al., 1983"
  final String title; // Full title of the source
  final String publisher;
  final String url;

  const Citation({
    required this.id,
    required this.label,
    required this.title,
    required this.publisher,
    required this.url,
  });
}

/// Catalog of externally published, independently verifiable sources used
/// throughout the app. These are general, peer-reviewed or reputable-health-
/// organization sources for the *techniques and instruments* the app uses.
///
/// They do NOT back the specific point-value estimates (e.g. "-5.8 points")
/// shown on some recommendations — those come from SelfCare Together's own
/// pilot study and are disclosed separately. See [pilotDerivedRecommendationTitles].
class Citations {
  static const pss10 = Citation(
    id: 'pss10',
    label: 'Cohen, Kamarck & Mermelstein (1983)',
    title: 'A Global Measure of Perceived Stress',
    publisher: 'Journal of Health and Social Behavior',
    url: 'https://pubmed.ncbi.nlm.nih.gov/6668417/',
  );

  static const therapy = Citation(
    id: 'therapy',
    label: 'NIMH — Psychotherapies',
    title: 'Psychotherapies',
    publisher: 'National Institute of Mental Health',
    url: 'https://www.nimh.nih.gov/health/topics/psychotherapies',
  );

  static const journaling = Citation(
    id: 'journaling',
    label: 'University of Rochester Medical Center',
    title: 'Journaling for Emotional Wellness',
    publisher: 'URMC Health Encyclopedia',
    url:
        'https://www.urmc.rochester.edu/encyclopedia/content.aspx?contenttypeid=1&contentid=4552',
  );

  static const socialSupport = Citation(
    id: 'social_support',
    label: 'APA — Strengthen Your Support Network',
    title: 'Manage Stress: Strengthen Your Support Network',
    publisher: 'American Psychological Association',
    url: 'https://www.apa.org/topics/stress/manage-social-support',
  );

  static const exercise = Citation(
    id: 'exercise',
    label: 'Harvard Health — Exercising to Relax',
    title: 'Exercising to Relax',
    publisher: 'Harvard Medical School',
    url: 'https://www.health.harvard.edu/staying-healthy/exercising-to-relax',
  );

  static const meditation = Citation(
    id: 'meditation',
    label: 'NCCIH — Meditation and Mindfulness',
    title: 'Meditation and Mindfulness: Effectiveness and Safety',
    publisher: 'National Center for Complementary and Integrative Health',
    url:
        'https://www.nccih.nih.gov/health/meditation-and-mindfulness-what-you-need-to-know',
  );

  static const breathing = Citation(
    id: 'breathing',
    label: 'Harvard Health — Breath Control',
    title:
        'Relaxation Techniques: Breath Control Helps Quell Errant Stress Response',
    publisher: 'Harvard Medical School',
    url:
        'https://www.health.harvard.edu/mind-and-mood/relaxation-techniques-breath-control-helps-quell-errant-stress-response',
  );

  static const pmr = Citation(
    id: 'pmr',
    label: 'Mayo Clinic — Relaxation Techniques',
    title: 'Relaxation Techniques: Try These Steps to Lower Stress',
    publisher: 'Mayo Clinic',
    url:
        'https://www.mayoclinic.org/healthy-lifestyle/stress-management/in-depth/relaxation-technique/art-20045368',
  );

  static const grounding = Citation(
    id: 'grounding',
    label: 'Cleveland Clinic — Grounding Techniques',
    title: '13 Grounding Techniques for When You Feel Overwhelmed',
    publisher: 'Cleveland Clinic',
    url: 'https://health.clevelandclinic.org/grounding-techniques',
  );

  static const guidedImagery = Citation(
    id: 'guided_imagery',
    label: 'NIMH — Guided Visualization',
    title: 'Guided Visualization: Dealing with Stress',
    publisher: 'National Institute of Mental Health',
    url:
        'https://www.nimh.nih.gov/news/media/2021/guided-visualization-dealing-with-stress',
  );

  static const gratitude = Citation(
    id: 'gratitude',
    label: 'Harvard Health — Giving Thanks',
    title: 'Giving Thanks Can Make You Happier',
    publisher: 'Harvard Medical School',
    url:
        'https://www.health.harvard.edu/healthbeat/giving-thanks-can-make-you-happier',
  );

  static const diveReflex = Citation(
    id: 'dive_reflex',
    label: 'Healthline — The Dive Reflex',
    title: 'The Mammalian Dive Reflex',
    publisher: 'Healthline',
    url: 'https://www.healthline.com/health/dive-reflex',
  );

  static const generalStressTips = Citation(
    id: 'general_stress_tips',
    label: 'APA — Healthy Ways to Handle Stress',
    title: "11 Healthy Ways to Handle Life's Stressors",
    publisher: 'American Psychological Association',
    url: 'https://www.apa.org/topics/stress/tips',
  );

  static const all = <Citation>[
    pss10,
    therapy,
    journaling,
    socialSupport,
    exercise,
    meditation,
    breathing,
    pmr,
    grounding,
    guidedImagery,
    gratitude,
    diveReflex,
    generalStressTips,
  ];
}

/// Maps a generated [Recommendation] to the external citation that best
/// supports the *general technique* it recommends. Matched by title since
/// recommendations aren't persisted with a citation id (avoids a Hive schema
/// migration) and titles are stable strings defined in AlgorithmService.
Citation? citationFor(Recommendation rec) {
  final title = rec.title;

  if (title.contains('Breathing Exercise') || title.contains('Box Breathing')) {
    return Citations.breathing;
  }
  if (title.contains('Try Professional Support')) return Citations.therapy;
  if (title.contains('Journaling') || title.contains('Worry Dump')) {
    return Citations.journaling;
  }
  if (title.contains('Get Moving') ||
      title.contains('5-Minute Walk') ||
      title.contains('Desk Stretches')) {
    return Citations.exercise;
  }
  if (title.contains('Connect With Others') ||
      title.contains('Meet Someone in Person')) {
    return Citations.socialSupport;
  }
  if (title.contains('Calm Your Mind') || title.contains('Body Scan')) {
    return Citations.meditation;
  }
  if (title.contains('Muscle Relaxation')) return Citations.pmr;
  if (title.contains('Grounding')) return Citations.grounding;
  if (title.contains('Safe Place Visualization')) return Citations.guidedImagery;
  if (title.contains('Gratitude')) return Citations.gratitude;
  if (title.contains('Cold Water Reset')) return Citations.diveReflex;
  if (title.contains('Add Active Stress Management') ||
      title.contains('Balance Your Coping') ||
      title.contains('Positive Affirmations') ||
      title.startsWith('📈 Increase')) {
    return Citations.generalStressTips;
  }

  return null;
}

/// Titles of recommendations whose quantified claim (e.g. "-5.8 points")
/// comes from SelfCare Together's own pilot study (n=50 participants),
/// not from the external citation above. Shown with a disclosure so the
/// specific number is never presented as if it were externally validated.
const Set<String> pilotDerivedRecommendationTitles = {
  '🏥 Try Professional Support',
  '📝 Start Journaling (3 Minutes)',
  '🏃 Get Moving',
  '🤝 Connect With Others',
  '🧘 Calm Your Mind',
  '💰 Financial Stress Support',
  '⏰ Reclaim Your Time',
  '⚖️ Balance Your Coping',
  '💪 Add Active Stress Management',
};

bool isPilotDerived(Recommendation rec) =>
    pilotDerivedRecommendationTitles.contains(rec.title);
