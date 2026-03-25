import '../../../models/therapy_module_model.dart';

/// Static registry of all 30 therapy modules.
/// Each module is a fully structured TherapyModuleModel with instructions,
/// difficulty, target skills, and category metadata.
class TherapyModulesRegistry {
  TherapyModulesRegistry._();

  static final List<TherapyModuleModel> allModules =
      _baseModules.map(_withReferenceMedia).toList();

  static final List<TherapyModuleModel> _baseModules = [
    // ── COMMUNICATION SKILLS (5) ──────────────────────────────
    TherapyModuleModel(
      id: 'comm_01',
      title: 'Picture Exchange',
      objective: 'Learn to express needs and wants using picture cards',
      conditionTypes: ['ASD', 'Speech Delay', 'Down Syndrome'],
      ageRange: '2-8',
      skillCategory: 'Communication',
      difficultyLevel: 1,
      materials: ['Picture cards (printed or digital)', 'Reward items'],
      instructions: [
        'Show the child a set of picture cards representing common objects or actions.',
        'Demonstrate exchanging a picture card to request an item.',
        'Encourage the child to pick a card and hand it to you to make a request.',
        'When the child successfully exchanges a card, provide the requested item with praise.',
        'Gradually increase the number of cards and introduce action cards.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can independently exchange 3-5 picture cards to request items.',
      targetSkills: ['requesting', 'expressing_needs', 'choice_making'],
      activityType: 'interactive',
      iconName: 'image',
    ),
    TherapyModuleModel(
      id: 'comm_02',
      title: 'Story Sequencing',
      objective:
          'Arrange story events in the correct order to build narrative skills',
      conditionTypes: ['ASD', 'Speech Delay', 'Learning Disability'],
      ageRange: '4-10',
      skillCategory: 'Communication',
      difficultyLevel: 2,
      materials: ['Story cards with 3-6 panels', 'Timer'],
      instructions: [
        'Present a set of jumbled story cards showing a simple sequence (e.g., waking up, brushing teeth, eating breakfast).',
        'Ask the child: "What happens first?"',
        'Guide the child to arrange the cards in order, prompting with "What happens next?"',
        'Once arranged, ask the child to tell the story using the ordered cards.',
        'Praise correct sequences and gently correct mistakes by narrating the story together.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can correctly sequence a 4-panel story and narrate it.',
      targetSkills: ['narrative_skills', 'sequencing', 'vocabulary'],
      activityType: 'interactive',
      iconName: 'auto_stories',
    ),
    TherapyModuleModel(
      id: 'comm_03',
      title: 'Conversation Cards',
      objective: 'Practice turn-taking and topic maintenance in conversation',
      conditionTypes: ['ASD', 'ADHD', 'Social Anxiety'],
      ageRange: '5-12',
      skillCategory: 'Communication',
      difficultyLevel: 3,
      materials: ['Conversation prompt cards', 'Sand timer'],
      instructions: [
        'Place a stack of conversation cards face down between you and the child.',
        'Take turns drawing a card and answering the prompt (e.g., "What is your favorite animal and why?").',
        'Model turn-taking: listen while the child speaks, then respond with a follow-up question.',
        'Use a sand timer (30 seconds) to practice speaking for an appropriate duration.',
        'Praise the child for listening, waiting their turn, and asking questions.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can maintain a 3-turn conversation on a given topic.',
      targetSkills: ['turn_taking', 'topic_maintenance', 'listening'],
      activityType: 'interactive',
      iconName: 'forum',
    ),
    TherapyModuleModel(
      id: 'comm_04',
      title: 'Describe & Guess',
      objective: 'Build descriptive vocabulary through a guessing game',
      conditionTypes: ['ASD', 'Speech Delay', 'Learning Disability'],
      ageRange: '4-10',
      skillCategory: 'Communication',
      difficultyLevel: 2,
      materials: ['Mystery bag with objects', 'Picture cards'],
      instructions: [
        'Place an object inside a mystery bag without the child seeing it.',
        'Ask the child to reach in and feel the object without looking.',
        'Prompt: "Tell me what it feels like. Is it soft or hard? Big or small?"',
        'After describing, the child guesses what the object is.',
        'Take turns — let the child hide an object for you to describe and guess.',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child uses at least 3 descriptive words to describe objects.',
      targetSkills: [
        'vocabulary',
        'descriptive_language',
        'sensory_integration',
      ],
      activityType: 'interactive',
      iconName: 'help_outline',
    ),
    TherapyModuleModel(
      id: 'comm_05',
      title: 'Ask Me Anything',
      objective: 'Practice forming questions using who, what, where, when, why',
      conditionTypes: ['ASD', 'Speech Delay', 'Down Syndrome'],
      ageRange: '5-12',
      skillCategory: 'Communication',
      difficultyLevel: 3,
      materials: [
        'Question word cards (Who, What, Where, When, Why)',
        'Picture scenes',
      ],
      instructions: [
        'Show the child a detailed picture scene (e.g., a park, a classroom).',
        'Present question word cards and explain each one.',
        'Model a question: "WHO is playing on the swing?"',
        'Ask the child to pick a question word card and form a question about the picture.',
        'Answer their question, then encourage them to ask another using a different word.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can form questions using at least 3 different question words.',
      targetSkills: ['question_formation', 'curiosity', 'grammar'],
      activityType: 'interactive',
      iconName: 'quiz',
    ),

    // ── EMOTIONAL RECOGNITION (3) ─────────────────────────────
    TherapyModuleModel(
      id: 'emo_01',
      title: 'Feeling Faces',
      objective: 'Identify and name emotions from facial expressions',
      conditionTypes: ['ASD', 'ADHD', 'Social Anxiety'],
      ageRange: '3-9',
      skillCategory: 'Emotional Recognition',
      difficultyLevel: 1,
      materials: ['Emotion cards with faces', 'Mirror'],
      instructions: [
        'Show the child emotion cards one at a time (happy, sad, angry, scared, surprised).',
        'For each card, name the emotion and describe the facial features.',
        'Ask the child to find the matching emotion from a set of cards.',
        'Use a mirror — make an emotion face and ask the child to guess what you feel.',
        'Ask: "When do YOU feel happy/sad/angry?" to connect emotions to experiences.',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child can correctly identify 5 basic emotions from facial expressions.',
      targetSkills: [
        'emotion_identification',
        'facial_reading',
        'self_awareness',
      ],
      activityType: 'interactive',
      iconName: 'mood',
    ),
    TherapyModuleModel(
      id: 'emo_02',
      title: 'Emotion Thermometer',
      objective: 'Learn to rate and express the intensity of feelings',
      conditionTypes: ['ASD', 'ADHD', 'Anxiety'],
      ageRange: '5-12',
      skillCategory: 'Emotional Recognition',
      difficultyLevel: 2,
      materials: ['Thermometer visual (1-5 scale)', 'Scenario cards'],
      instructions: [
        'Introduce the emotion thermometer: 1 = "a little", 5 = "a LOT".',
        'Read a scenario card (e.g., "Your friend took your toy without asking").',
        'Ask: "How would this make you feel? Point to the thermometer."',
        'Discuss: "What could you do if your thermometer is at a 4 or 5?"',
        'Practice calming strategies: deep breaths for high temperatures, celebrating for happy.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can rate emotional intensity and suggest a coping strategy.',
      targetSkills: [
        'emotion_regulation',
        'self_awareness',
        'coping_strategies',
      ],
      activityType: 'interactive',
      iconName: 'thermostat',
    ),
    TherapyModuleModel(
      id: 'emo_03',
      title: 'Mood Story Builder',
      objective: 'Connect events to emotions by creating simple stories',
      conditionTypes: ['ASD', 'Learning Disability'],
      ageRange: '5-12',
      skillCategory: 'Emotional Recognition',
      difficultyLevel: 3,
      materials: ['Blank story templates', 'Emotion stickers', 'Crayons'],
      instructions: [
        'Give the child a simple story template with blanks for feelings.',
        'Read the story starter: "Today at school, something happened… it made me feel ___."',
        'Let the child choose an emotion sticker to fill the blank.',
        'Ask: "What happened that made you feel that way?" and write or draw it together.',
        'End the story with: "To feel better, I can ___" and help them fill in a coping strategy.',
      ],
      durationMinutes: 18,
      expectedOutcomes:
          'Child can create a simple cause-and-effect narrative linking events to feelings.',
      targetSkills: [
        'emotional_awareness',
        'narrative_skills',
        'coping_strategies',
      ],
      activityType: 'guided',
      iconName: 'menu_book',
    ),

    // ── COGNITIVE DEVELOPMENT (4) ─────────────────────────────
    TherapyModuleModel(
      id: 'cog_01',
      title: 'Odd One Out',
      objective: 'Identify the item that does not belong in a group',
      conditionTypes: ['ASD', 'ADHD', 'Learning Disability', 'Down Syndrome'],
      ageRange: '3-8',
      skillCategory: 'Cognitive',
      difficultyLevel: 1,
      materials: ['Sets of 4 objects/pictures'],
      instructions: [
        'Show the child 4 items where 3 belong to a category and 1 does not (e.g., apple, banana, orange, shoe).',
        'Ask: "Which one does NOT belong? Which one is different?"',
        'When the child answers, ask: "Why doesn\'t it belong?"',
        'Start with very obvious differences (fruit vs. shoe), then increase subtlety (3 red objects + 1 blue).',
        'Celebrate correct answers and gently guide incorrect ones.',
      ],
      durationMinutes: 10,
      expectedOutcomes:
          'Child can identify the odd item and explain why in simple terms.',
      targetSkills: ['categorization', 'logical_thinking', 'reasoning'],
      activityType: 'interactive',
      iconName: 'filter_alt',
    ),
    TherapyModuleModel(
      id: 'cog_02',
      title: 'What Comes Next',
      objective: 'Recognize and continue simple patterns',
      conditionTypes: ['ASD', 'ADHD', 'Learning Disability'],
      ageRange: '4-10',
      skillCategory: 'Cognitive',
      difficultyLevel: 2,
      materials: ['Colored blocks', 'Pattern cards'],
      instructions: [
        'Create a simple pattern: red, blue, red, blue, ___.',
        'Ask: "What comes next?" and let the child place the next block.',
        'Progress to more complex patterns: red, red, blue, red, red, blue, ___.',
        'Try shape patterns: circle, square, circle, square, ___.',
        'Let the child create their own pattern for you to continue.',
      ],
      durationMinutes: 12,
      expectedOutcomes: 'Child can identify and continue AB and ABB patterns.',
      targetSkills: ['pattern_recognition', 'prediction', 'sequencing'],
      activityType: 'interactive',
      iconName: 'view_module',
    ),
    TherapyModuleModel(
      id: 'cog_03',
      title: 'Category Sorting',
      objective: 'Sort objects into categories based on shared properties',
      conditionTypes: ['ASD', 'Down Syndrome', 'Learning Disability'],
      ageRange: '3-9',
      skillCategory: 'Cognitive',
      difficultyLevel: 2,
      materials: ['Sorting bins or labeled plates', 'Mixed object set'],
      instructions: [
        'Place 2-3 labeled sorting bins (e.g., "Animals", "Food", "Vehicles").',
        'Give the child a mixed pile of picture cards or toy objects.',
        'Demonstrate: "A dog is an animal, so it goes in this bin."',
        'Let the child sort the remaining items, asking "Where does this go?"',
        'Increase challenge by using less obvious categories (things that are cold vs. hot).',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child can sort 10+ items into 3 categories with minimal help.',
      targetSkills: ['classification', 'grouping', 'vocabulary'],
      activityType: 'interactive',
      iconName: 'category',
    ),
    TherapyModuleModel(
      id: 'cog_04',
      title: 'Cause & Effect',
      objective:
          'Understand what happens and why through cause-effect scenarios',
      conditionTypes: ['ASD', 'ADHD', 'Learning Disability'],
      ageRange: '5-12',
      skillCategory: 'Cognitive',
      difficultyLevel: 3,
      materials: ['Cause-and-effect cards', 'Story scenarios'],
      instructions: [
        'Show a "cause" card (e.g., picture of rain clouds) and an "effect" card (puddles on the ground).',
        'Explain: "Because it rained, there are puddles."',
        'Mix up several cause-and-effect pairs; ask the child to match them together.',
        'Present a cause and ask: "What do you think will happen?"',
        'Progress to social cause-and-effect: "If you share your toys, your friend might feel ___."',
      ],
      durationMinutes: 15,
      expectedOutcomes: 'Child can correctly match 5+ cause-and-effect pairs.',
      targetSkills: ['logical_reasoning', 'prediction', 'social_understanding'],
      activityType: 'interactive',
      iconName: 'compare_arrows',
    ),

    // ── MEMORY TRAINING (3) ───────────────────────────────────
    TherapyModuleModel(
      id: 'mem_01',
      title: 'Sequence Recall',
      objective: 'Remember and repeat sequences of increasing length',
      conditionTypes: ['ASD', 'ADHD', 'Learning Disability'],
      ageRange: '3-10',
      skillCategory: 'Memory',
      difficultyLevel: 1,
      materials: ['Colored buttons or beads', 'A tray'],
      instructions: [
        'Place 2 colored beads in a row (e.g., red, blue). Let the child look for 5 seconds.',
        'Cover them. Ask: "What colors were there, and in what order?"',
        'If correct, add one more bead and repeat.',
        'If incorrect, reduce by one and try again — no pressure!',
        'Celebrate each length milestone: "You remembered 4 in a row! Amazing!"',
      ],
      durationMinutes: 10,
      expectedOutcomes: 'Child can recall a sequence of 3-4 items.',
      targetSkills: ['short_term_memory', 'sequencing', 'attention'],
      activityType: 'interactive',
      iconName: 'format_list_numbered',
    ),
    TherapyModuleModel(
      id: 'mem_02',
      title: 'Shopping List Memory',
      objective: 'Remember a list of items through a pretend shopping game',
      conditionTypes: ['ASD', 'ADHD', 'Down Syndrome'],
      ageRange: '4-10',
      skillCategory: 'Memory',
      difficultyLevel: 2,
      materials: ['Toy food or picture cards', 'Shopping basket'],
      instructions: [
        'Tell the child: "We need to buy 3 things: milk, apples, and bread."',
        'Repeat the list together once.',
        'Send the child to the pretend "shop" (a table with various items) to find the right ones.',
        'Check the basket together: "Did we get everything?"',
        'Increase to 4-5 items as the child improves.',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child can remember and retrieve 3-4 items from a spoken list.',
      targetSkills: ['working_memory', 'listening', 'following_instructions'],
      activityType: 'interactive',
      iconName: 'shopping_cart',
    ),
    TherapyModuleModel(
      id: 'mem_03',
      title: 'Story Retell',
      objective: 'Listen to a short story and retell it from memory',
      conditionTypes: ['ASD', 'Speech Delay', 'Learning Disability'],
      ageRange: '5-12',
      skillCategory: 'Memory',
      difficultyLevel: 3,
      materials: ['Short story book or printed story (3-5 sentences)'],
      instructions: [
        'Read a very short story aloud to the child (3-5 sentences).',
        'After reading, ask: "Can you tell me what happened in the story?"',
        'If the child gets stuck, prompt with: "Who was in the story?" "What did they do?"',
        'Use picture cues if needed to support recall.',
        'Praise any details remembered and gradually reduce prompts over sessions.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can retell the main idea and 2-3 details of a short story.',
      targetSkills: ['long_term_recall', 'comprehension', 'narrative_skills'],
      activityType: 'guided',
      iconName: 'auto_stories',
    ),

    // ── ATTENTION IMPROVEMENT (3) ─────────────────────────────
    TherapyModuleModel(
      id: 'att_01',
      title: 'Spot the Difference',
      objective: 'Find differences between two nearly identical pictures',
      conditionTypes: ['ADHD', 'ASD', 'Learning Disability'],
      ageRange: '4-10',
      skillCategory: 'Attention',
      difficultyLevel: 1,
      materials: ['Spot-the-difference picture pairs'],
      instructions: [
        'Show the child two side-by-side pictures that look almost the same.',
        'Say: "These pictures look the same, but some things are different. Can you find them?"',
        'Start with 3 differences and large, obvious changes.',
        'When the child finds one, circle it together and praise them.',
        'Increase to 5+ differences with subtler changes as skills improve.',
      ],
      durationMinutes: 10,
      expectedOutcomes:
          'Child can find 3+ differences in a picture pair within 2 minutes.',
      targetSkills: ['visual_attention', 'focus', 'detail_observation'],
      activityType: 'interactive',
      iconName: 'find_in_page',
    ),
    TherapyModuleModel(
      id: 'att_02',
      title: 'Follow the Leader',
      objective: 'Sustain attention by copying a sequence of movements',
      conditionTypes: ['ADHD', 'ASD', 'Down Syndrome'],
      ageRange: '3-9',
      skillCategory: 'Attention',
      difficultyLevel: 2,
      materials: ['Open space', 'Timer'],
      instructions: [
        'Stand facing the child. Say: "Copy everything I do!"',
        'Start with simple movements: clap, stomp, wave.',
        'Add a sequence: clap-clap-stomp. Ask the child to repeat it exactly.',
        'Increase the sequence length gradually.',
        'Switch roles! Let the child be the leader while you copy.',
      ],
      durationMinutes: 10,
      expectedOutcomes: 'Child can copy a 4-step movement sequence.',
      targetSkills: ['sustained_attention', 'imitation', 'motor_planning'],
      activityType: 'interactive',
      iconName: 'directions_run',
    ),
    TherapyModuleModel(
      id: 'att_03',
      title: 'Color Word Challenge',
      objective:
          'Practice selective attention with a Stroop-style color/word task',
      conditionTypes: ['ADHD', 'ASD'],
      ageRange: '6-12',
      skillCategory: 'Attention',
      difficultyLevel: 3,
      materials: ['Color word cards (word "RED" printed in blue ink, etc.)'],
      instructions: [
        'Show a card where the word "BLUE" is printed in red ink.',
        'Ask: "What COLOR is the word printed in?" (Answer: red)',
        'Start slowly and praise correct answers.',
        'Speed up as the child gets better — use a timer to track improvement.',
        'Track how many the child gets correct in 30 seconds each session.',
      ],
      durationMinutes: 10,
      expectedOutcomes:
          'Child can correctly identify 8+ ink colors in 30 seconds.',
      targetSkills: [
        'selective_attention',
        'inhibitory_control',
        'processing_speed',
      ],
      activityType: 'game',
      iconName: 'palette',
    ),

    // ── SOCIAL INTERACTION (3) ────────────────────────────────
    TherapyModuleModel(
      id: 'soc_01',
      title: 'Greeting Practice',
      objective: 'Learn and practice basic social greetings',
      conditionTypes: ['ASD', 'Social Anxiety', 'Down Syndrome'],
      ageRange: '3-8',
      skillCategory: 'Social Interaction',
      difficultyLevel: 1,
      materials: ['Puppets or stuffed animals', 'Mirror'],
      instructions: [
        'Model a greeting using a puppet: "Hi! My name is Teddy! What\'s your name?"',
        'Encourage the child to greet the puppet back.',
        'Practice waving, saying hello, and making eye contact (use the mirror).',
        'Role-play: pretend to be a new friend arriving — practice the full greeting.',
        'Practice different greetings: morning, afternoon, saying goodbye.',
      ],
      durationMinutes: 10,
      expectedOutcomes:
          'Child can independently greet someone with a wave and verbal hello.',
      targetSkills: ['social_initiation', 'eye_contact', 'verbal_greeting'],
      activityType: 'interactive',
      iconName: 'waving_hand',
    ),
    TherapyModuleModel(
      id: 'soc_02',
      title: 'Sharing & Taking Turns',
      objective: 'Practice sharing materials and waiting for a turn',
      conditionTypes: ['ASD', 'ADHD', 'Down Syndrome'],
      ageRange: '3-9',
      skillCategory: 'Social Interaction',
      difficultyLevel: 2,
      materials: ['Board game or shared toy', 'Turn-taking visual timer'],
      instructions: [
        'Choose a simple board/card game or a shared toy (e.g., a ball).',
        'Use a visual timer: "It\'s your turn for 30 seconds, then my turn."',
        'Model waiting: "I\'m waiting patiently because it\'s your turn right now."',
        'When the child waits, praise them: "Great waiting! Now it\'s your turn!"',
        'Discuss after: "How did it feel to take turns? Was it hard?"',
      ],
      durationMinutes: 12,
      expectedOutcomes: 'Child can wait for a turn with minimal prompting.',
      targetSkills: ['sharing', 'patience', 'cooperative_play'],
      activityType: 'interactive',
      iconName: 'group',
    ),
    TherapyModuleModel(
      id: 'soc_03',
      title: 'Role Play Scenarios',
      objective:
          'Act out social situations to build empathy and perspective-taking',
      conditionTypes: ['ASD', 'Social Anxiety'],
      ageRange: '5-12',
      skillCategory: 'Social Interaction',
      difficultyLevel: 3,
      materials: ['Scenario cards', 'Props (optional)'],
      instructions: [
        'Draw a scenario card (e.g., "A friend falls down and cries").',
        'Ask: "What would you do? How does the friend feel?"',
        'Act it out together — the child plays themselves, you play the other person.',
        'Switch roles so the child experiences the other person\'s perspective.',
        'Discuss: "Why did the friend feel sad? What made them feel better?"',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can identify another person\'s feelings and suggest an appropriate response.',
      targetSkills: ['perspective_taking', 'empathy', 'social_problem_solving'],
      activityType: 'interactive',
      iconName: 'theater_comedy',
    ),

    // ── SPEECH & LANGUAGE (3) ─────────────────────────────────
    TherapyModuleModel(
      id: 'spl_01',
      title: 'Sound Imitation',
      objective: 'Practice producing individual sounds and syllables',
      conditionTypes: ['Speech Delay', 'ASD', 'Down Syndrome'],
      ageRange: '2-7',
      skillCategory: 'Speech & Language',
      difficultyLevel: 1,
      materials: ['Mirror', 'Sound cards'],
      instructions: [
        'Sit with the child in front of a mirror.',
        'Make a simple sound: "ba ba ba" and show how your mouth moves.',
        'Encourage the child to copy the sound while looking in the mirror.',
        'Try different sounds: "ma", "da", "ga", "pa".',
        'When the child can imitate a sound, pair it with an object: "ba — ball!"',
      ],
      durationMinutes: 10,
      expectedOutcomes: 'Child can imitate 5+ individual sounds.',
      targetSkills: ['phoneme_production', 'oral_motor', 'imitation'],
      activityType: 'guided',
      iconName: 'record_voice_over',
    ),
    TherapyModuleModel(
      id: 'spl_02',
      title: 'Rhyme Time',
      objective: 'Develop phonological awareness through rhyming games',
      conditionTypes: ['Speech Delay', 'ASD', 'Learning Disability'],
      ageRange: '4-9',
      skillCategory: 'Speech & Language',
      difficultyLevel: 2,
      materials: ['Rhyming word pairs', 'Picture cards'],
      instructions: [
        'Say two words: "cat" and "hat". Ask: "Do these sound the same at the end?"',
        'Practice with several pairs: dog/fog, sun/fun, tree/me.',
        'Show picture cards and ask: "Can you find two that rhyme?"',
        'Play a game: "I say a word, you think of a rhyming word! Ready? – Ball!"',
        'Sing simple nursery rhymes together, pausing for the child to fill in the rhyming word.',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child can identify rhyming pairs and generate 2-3 rhymes.',
      targetSkills: [
        'phonological_awareness',
        'auditory_discrimination',
        'vocabulary',
      ],
      activityType: 'interactive',
      iconName: 'music_note',
    ),
    TherapyModuleModel(
      id: 'spl_03',
      title: 'Sentence Builder',
      objective: 'Construct simple grammatically correct sentences',
      conditionTypes: ['Speech Delay', 'ASD', 'Down Syndrome'],
      ageRange: '5-12',
      skillCategory: 'Speech & Language',
      difficultyLevel: 3,
      materials: ['Word cards (nouns, verbs, adjectives)', 'Sentence strips'],
      instructions: [
        'Lay out word cards in groups: people (boy, girl), actions (runs, eats), things (apple, ball).',
        'Model building a sentence: "The boy eats an apple."',
        'Ask the child to pick one card from each group and build a sentence.',
        'Read the sentence together. Does it make sense?',
        'Add adjective cards (big, red, happy) to make sentences longer and more descriptive.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can construct 3+ word sentences with subject-verb-object structure.',
      targetSkills: ['syntax', 'grammar', 'sentence_formation'],
      activityType: 'interactive',
      iconName: 'text_fields',
    ),

    // ── PROBLEM SOLVING (3) ───────────────────────────────────
    TherapyModuleModel(
      id: 'prob_01',
      title: 'Simple Puzzles',
      objective: 'Develop spatial reasoning by completing jigsaw-style puzzles',
      conditionTypes: ['ASD', 'Down Syndrome', 'Learning Disability'],
      ageRange: '3-8',
      skillCategory: 'Problem Solving',
      difficultyLevel: 1,
      materials: ['Simple puzzles (4-12 pieces)'],
      instructions: [
        'Start with a 4-piece puzzle with a familiar image (animal, vehicle).',
        'Help the child identify corner and edge pieces first.',
        'Guide: "Look at the picture on the box. Where does this piece go?"',
        'Let the child try placing pieces independently, offering help only if stuck.',
        'Gradually increase to 8-12 piece puzzles as confidence grows.',
      ],
      durationMinutes: 12,
      expectedOutcomes: 'Child can complete a 6-piece puzzle independently.',
      targetSkills: ['spatial_reasoning', 'problem_solving', 'fine_motor'],
      activityType: 'interactive',
      iconName: 'extension',
    ),
    TherapyModuleModel(
      id: 'prob_02',
      title: 'What Would You Do?',
      objective:
          'Practice decision-making and safety awareness through scenarios',
      conditionTypes: ['ASD', 'ADHD', 'Down Syndrome'],
      ageRange: '4-12',
      skillCategory: 'Problem Solving',
      difficultyLevel: 2,
      materials: ['Scenario cards'],
      instructions: [
        'Read a scenario: "You are at the park and can\'t find your parent. What would you do?"',
        'Give 3 choices (A, B, C) and ask the child to choose the safest one.',
        'Discuss why the correct answer is safest.',
        'Try different scenarios: fire drill, stranger offering candy, feeling sick.',
        'Role-play the correct response together.',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child can identify the safest response in 3+ common scenarios.',
      targetSkills: [
        'decision_making',
        'safety_awareness',
        'critical_thinking',
      ],
      activityType: 'interactive',
      iconName: 'psychology',
    ),
    TherapyModuleModel(
      id: 'prob_03',
      title: 'Maze Runner',
      objective: 'Navigate mazes to build planning and sequential thinking',
      conditionTypes: ['ADHD', 'ASD', 'Learning Disability'],
      ageRange: '4-10',
      skillCategory: 'Problem Solving',
      difficultyLevel: 3,
      materials: ['Printed mazes of increasing difficulty', 'Pencil/crayon'],
      instructions: [
        'Start with a very simple maze (few turns, wide paths).',
        'Say: "Let\'s find the way from START to FINISH! Use your finger first."',
        'After tracing with a finger, let the child draw the path with a pencil.',
        'If they hit a dead end, say: "That\'s okay! Back up and try another way."',
        'Increase maze complexity as the child succeeds.',
      ],
      durationMinutes: 10,
      expectedOutcomes:
          'Child can complete a medium-complexity maze independently.',
      targetSkills: ['planning', 'sequential_thinking', 'fine_motor'],
      activityType: 'interactive',
      iconName: 'route',
    ),

    // ── SENSORY ACTIVITIES (3) ────────────────────────────────
    TherapyModuleModel(
      id: 'sen_01',
      title: 'Texture Explorer',
      objective:
          'Explore different textures to develop tactile processing skills',
      conditionTypes: ['ASD', 'Sensory Processing Disorder'],
      ageRange: '2-8',
      skillCategory: 'Sensory',
      difficultyLevel: 1,
      materials: [
        'Texture board or bag with: sandpaper, cotton, silk, sponge, foil',
      ],
      instructions: [
        'Present textures one at a time. Let the child touch at their own comfort level.',
        'Name each texture: "This one is rough. This one is soft."',
        'Ask: "Do you like this one? Is it smooth or bumpy?"',
        'Sort textures into "I like" and "I don\'t like" piles — both are okay!',
        'Gently introduce less preferred textures with an "I can try" approach.',
      ],
      durationMinutes: 10,
      expectedOutcomes:
          'Child can tolerate touching 4+ textures and name 3 descriptions.',
      targetSkills: ['tactile_processing', 'sensory_tolerance', 'vocabulary'],
      activityType: 'guided',
      iconName: 'touch_app',
    ),
    TherapyModuleModel(
      id: 'sen_02',
      title: 'Sound Sorting',
      objective:
          'Discriminate between different sounds and match them to sources',
      conditionTypes: ['ASD', 'Sensory Processing Disorder', 'ADHD'],
      ageRange: '3-9',
      skillCategory: 'Sensory',
      difficultyLevel: 2,
      materials: [
        'Sound recordings or instruments',
        'Picture cards of sources',
      ],
      instructions: [
        'Play a sound (e.g., a dog barking) and show 3 picture cards.',
        'Ask: "Which picture makes this sound?"',
        'Progress to environmental sounds: doorbell, rain, car horn.',
        'Play two sounds and ask: "Were they the same or different?"',
        'Create a sound sorting game: loud vs. quiet, high vs. low.',
      ],
      durationMinutes: 12,
      expectedOutcomes:
          'Child can match 5+ sounds to their sources and sort by volume.',
      targetSkills: ['auditory_discrimination', 'listening', 'categorization'],
      activityType: 'interactive',
      iconName: 'hearing',
    ),
    TherapyModuleModel(
      id: 'sen_03',
      title: 'Calm Down Toolkit',
      objective:
          'Learn and practice self-regulation techniques using sensory tools',
      conditionTypes: ['ASD', 'ADHD', 'Anxiety', 'Sensory Processing Disorder'],
      ageRange: '3-12',
      skillCategory: 'Sensory',
      difficultyLevel: 2,
      materials: [
        'Stress ball',
        'Weighted lap pad',
        'Noise-canceling headphones',
        'Calm-down jar',
      ],
      instructions: [
        'Introduce the calm-down toolkit: "These are tools that can help when you feel upset or overwhelmed."',
        'Demonstrate each tool: squeeze the stress ball, rest with the weighted pad, shake the calm-down jar.',
        'Ask: "Which one feels the best to you?"',
        'Practice using tools when calm so the child knows what to do when upset.',
        'Create a visual "When I feel upset, I can…" chart together with the child\'s preferred tools.',
      ],
      durationMinutes: 15,
      expectedOutcomes:
          'Child can independently select and use a calming tool when prompted.',
      targetSkills: [
        'self_regulation',
        'sensory_coping',
        'emotional_awareness',
      ],
      activityType: 'guided',
      iconName: 'self_improvement',
    ),
  ];

  static TherapyModuleModel _withReferenceMedia(TherapyModuleModel module) {
    if (module.mediaUrls.isNotEmpty) return module;

    return TherapyModuleModel(
      id: module.id,
      title: module.title,
      objective: module.objective,
      conditionTypes: module.conditionTypes,
      ageRange: module.ageRange,
      skillCategory: module.skillCategory,
      difficultyLevel: module.difficultyLevel,
      materials: module.materials,
      instructions: module.instructions,
      durationMinutes: module.durationMinutes,
      safetyNotes: module.safetyNotes,
      expectedOutcomes: module.expectedOutcomes,
      createdBy: module.createdBy,
      isExpertApproved: module.isExpertApproved,
      mediaUrls: _referenceUrlsFor(module),
      iconName: module.iconName,
      activityType: module.activityType,
      targetSkills: module.targetSkills,
      prerequisites: module.prerequisites,
      adaptiveDifficultyEnabled: module.adaptiveDifficultyEnabled,
      createdAt: module.createdAt,
    );
  }

  static List<String> _referenceUrlsFor(TherapyModuleModel module) {
    final categoryTag = _categoryReferenceTag(module.skillCategory);
    final encoded = Uri.encodeComponent(categoryTag);
    return [
      'https://picsum.photos/seed/${module.id}_1/960/640',
      'https://picsum.photos/seed/${module.id}_2/960/640',
      'https://source.unsplash.com/960x640/?$encoded,child,therapy',
    ];
  }

  static String _categoryReferenceTag(String category) {
    switch (category.toLowerCase()) {
      case 'communication':
        return 'speech therapy';
      case 'emotional recognition':
        return 'child emotions learning';
      case 'cognitive':
        return 'kids puzzle learning';
      case 'memory':
        return 'memory cards activity';
      case 'attention':
        return 'focus training children';
      case 'motor skills':
        return 'fine motor skills child';
      case 'social skills':
      case 'social interaction':
        return 'children social play';
      case 'behavioral':
        return 'positive behavior support';
      case 'sensory':
        return 'sensory play activity';
      default:
        return 'child development activity';
    }
  }

  /// Get all unique skill categories.
  static List<String> get categories =>
      allModules.map((m) => m.skillCategory).toSet().toList()..sort();

  /// Filter modules by category.
  static List<TherapyModuleModel> byCategory(String category) =>
      allModules.where((m) => m.skillCategory == category).toList();

  /// Get a module by ID.
  static TherapyModuleModel? byId(String id) {
    try {
      return allModules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get modules appropriate for a given condition.
  static List<TherapyModuleModel> forCondition(String condition) =>
      allModules
          .where(
            (m) => m.conditionTypes.any(
              (c) => c.toLowerCase() == condition.toLowerCase(),
            ),
          )
          .toList();

  /// Get all module IDs.
  static List<String> get allIds => allModules.map((m) => m.id).toList();
}
