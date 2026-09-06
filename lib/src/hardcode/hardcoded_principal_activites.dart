import '../ember_core.dart';

class HardcodedPrincipalActivities {
  static final Set<PrincipalActivity> list = <PrincipalActivity>{
    gagaBall,
    boating,
    climbing,
    artsAndCraftsSkills,
    artsAndCrafts,
    tieDye,
    archery,
    archerySkillsRec,
    soccer,
    soccerSkills,
    cardGamesSkills,
    cardGames,
    yogaAndMindfulness,
    creativeWriting,
    music,
    cricket,
    friendshipBracelets,
    nineSquare,
    beachWalk,
    shelterBuilding,
    basketball,
    giantSwing,
    canoeing,
    pickleball,
    volleyball,
    volleyballSkills,
    hammockTime,
    lowRopes,
    birdWatching,
    planes,
    origami,
    rockArt,
    parachuteGames,
    painting,
    bingo,
    natureHike,
    fieldGames,
    hidingFromAuthority,
    cardGamesDND,
    aggressiveCompliments,
    fairyHouses,
    teenSkillsRec,
    bugBingo,
    badminton,
    outdoorLivingSkills,
    outdoorLivingSkillsSkills,
    stackingAndSkipping,
    skitShow,
    paperCrafts,
    stationary,
    magicTheGathering,
    waterTasting,
    tagGames,
    boxSitting,
    nappingSpots,
    riddlesAndGames,
    fuseBeads,
    safetyPatrol,
    gagaBallTournament,
    artInNature,
    something,
    somethingSkills,
    natureFigures,
    highV,
    decoupageTiles,
    posterMaking,
    dnd,
    artInNatureSkills,
    readingClub,
    circleOfLife,
    paintTheCounselor,
    chess,
    languageLearning,
    rugby,
    dance,
    comicBookCreation,
    graffitiWall,
    snorkeling,
    aussieAussieAussie,
    journaling,
    magicBehindAirplanes,
    cardAndBoardGames,
    singingChoir,
    kickball,
    drawing,
    selfCare,
    fashionDesign,
    calisthenics,
    livingLikeFarcus,
    carWashClub,
  };

  static final PrincipalActivity gagaBall = PrincipalActivity(
    id: 'gaga_ball-principal_activity-brn-Cs4UhTi',
    name: 'Gaga Ball',
    capacity: 20,
    description: 'Gaga Ball is a super fast-paced game played in a walled pit where everyone tries to hit a '
        'soft ball at other players\' legs, below the knees. If the ball touches you below the knees, you\'re'
        'out, and the last player left in the pit wins the round!',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity boating = PrincipalActivity(
    id: 'boating-principal_activity-brn-Cs4OyTi',
    name: 'Boating',
    capacity: 14,
    description: 'Grab a paddle and hop into a boat to explore the lagoon with your friends!',
    isSkillsRec: false,
    doubleSchedule: true,
    category: ActivityCategory.waterfront,
  );

  static final PrincipalActivity climbing = PrincipalActivity(
    id: 'climbing_wall-principal_activity-brn-Cs4OhTi',
    name: 'Climbing Wall',
    capacity: 12,
    description: 'Clip into a safety harness and see how high you can climb up the rock wall!',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity artsAndCraftsSkills = PrincipalActivity(
    id: 'arts_and_crafts-principal_activity-brn-6QeyXQW',
    name: 'Arts & Crafts',
    capacity: 16,
    description: 'Get creative with paint, paper, glue, and lots of other cool supplies to make '
        'your own awesome projects! You can draw, build, or design something totally unique to '
        'take home.',
    isSkillsRec: true,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity artsAndCrafts = PrincipalActivity(
    id: 'arts_and_crafts-principal_activity-brn-6QeyrQW',
    name: 'Arts & Crafts',
    capacity: 19,
    description: 'Get creative with paint, paper, glue, and lots of other cool supplies to make '
        'your own awesome projects! You can draw, build, or design something totally unique to '
        'take home.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity tieDye = PrincipalActivity(
    id: 'tie_dye-principal_activity-brn-09rnYJR',
    name: 'Tie Dye',
    capacity: 17,
    description: 'Twist, fold, and tie up a t-shirt or other fabric using rubber bands. Don\'t '
        'forget to bring something white to dye!!!',
    isSkillsRec: false,
    category: ActivityCategory.creative,
    maxAssignments: 1,
  );

  static final PrincipalActivity archery = PrincipalActivity(
    id: 'archery-principal_activity-brn-AkmWEg4',
    name: 'Archery',
    capacity: 16,
    description: 'Take aim at the target, draw back the string, and see if you can hit a bullseye!',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity archerySkillsRec = PrincipalActivity(
    id: 'archery_skills_rec-principal_activity-brn-AkmWET8',
    name: 'Archery',
    capacity: 16,
    description: 'Learn how to shoot a bow and arrow at a target and try to get a bullseye!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity soccerSkills = PrincipalActivity(
    id: 'soccer_skills-principal_activity-brn-l7g5Kwm',
    name: 'Soccer',
    capacity: 16,
    description: 'Practice your dribbling, passing, and shooting skills in this popular team sport.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity soccer = PrincipalActivity(
    id: 'soccer-principal_activity-brn-l7g5Kwm',
    name: 'Soccer',
    capacity: 16,
    description: 'Practice your dribbling, passing, and shooting skills in this popular team sport.',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity cardGamesSkills = PrincipalActivity(
    id: 'card_games-principal_activity-brn-3SObvwL',
    name: 'Card Games',
    capacity: 16,
    description: 'Grab a deck of cards and gather around a table with friends for some fun games!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity cardGames = PrincipalActivity(
    id: 'card_games-principal_activity-brn-3SObvrL',
    name: 'Card Games',
    capacity: 19,
    description: 'Grab a deck of cards and gather around a table with friends for some fun games!',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity yogaAndMindfulness = PrincipalActivity(
    id: 'yoga_&_mindfulness-principal_activity-brn-aBcDeF1',
    name: 'Yoga & Mindfulness',
    capacity: 16,
    description: 'Relax and find your center with some light stretching and mindfulness exercises.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity creativeWriting = PrincipalActivity(
    id: 'creative_writing-principal_activity-brn-bCdEfG2',
    name: 'Creative Writing',
    capacity: 16,
    description: 'Let your imagination run wild and write your own stories, poems, or plays.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity music = PrincipalActivity(
    id: 'music-principal_activity-brn-cDeFgH3',
    name: 'Music',
    capacity: 16,
    description: 'Learn to play an instrument, sing a song, or just jam out with your friends.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity cricket = PrincipalActivity(
    id: 'cricket-principal_activity-brn-dEfGhI4',
    name: 'Cricket',
    capacity: 16,
    description: 'Learn the basics of this classic bat-and-ball game, popular in many parts of the world.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity friendshipBracelets = PrincipalActivity(
    id: 'friendship_bracelets-principal_activity-brn-eFgHiJ5',
    name: 'Friendship Bracelets',
    capacity: 16,
    description: 'Weave colorful threads together to make bracelets for you and your friends.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity nineSquare = PrincipalActivity(
    id: '9_square-principal_activity-brn-fGhIjK6',
    name: '9 Square',
    capacity: 16,
    description: 'A fun and fast-paced game where you try to get to the center square by hitting a ball into other players\' squares.',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity beachWalk = PrincipalActivity(
    id: 'beach_walk-principal_activity-brn-gHiJkL7',
    name: 'Beach Walk',
    capacity: 16,
    description: 'Take a relaxing stroll along the beach, look for shells, and enjoy the ocean breeze.',
    isSkillsRec: false,
    category: ActivityCategory.waterfront,
  );

  static final PrincipalActivity shelterBuilding = PrincipalActivity(
    id: 'shelter_building-principal_activity-brn-hIjKlM8',
    name: 'Shelter Building',
    capacity: 16,
    description: 'Work with your team to build a shelter in the woods using only natural materials.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity basketball = PrincipalActivity(
    id: 'basketball-principal_activity-brn-iJkLmN9',
    name: 'Basketball',
    capacity: 16,
    description: 'Shoot some hoops with your friends and play a pickup game.',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity giantSwing = PrincipalActivity(
    id: 'giant_swing-principal_activity-brn-jKlMnO0',
    name: 'Giant Swing',
    capacity: 16,
    description: 'Get hoisted up high and then swing through the air for an exhilarating ride.',
    isSkillsRec: false,
    category: ActivityCategory.hidden,
    doubleSchedule: true,
  );

  static final PrincipalActivity canoeing = PrincipalActivity(
    id: 'canoeing-principal_activity-brn-kLmNoP1',
    name: 'Canoeing',
    capacity: 14,
    description: 'Grab a paddle and a friend and explore the water in a canoe.',
    isSkillsRec: false,
    doubleSchedule: true,
    category: ActivityCategory.waterfront,
  );

  static final PrincipalActivity pickleball = PrincipalActivity(
    id: 'pickleball-principal_activity-brn-lMnOqR2',
    name: 'Pickleball',
    capacity: 16,
    description: 'A fun paddle sport that combines elements of tennis, badminton, and table tennis.',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity volleyball = PrincipalActivity(
    id: 'volleyball-principal_activity-brn-mNoPrS3',
    name: 'Volleyball',
    capacity: 16,
    description: 'Bump, set, and spike your way to victory in a friendly game of volleyball.',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity volleyballSkills = PrincipalActivity(
    id: 'volleyball_skills-principal_activity-brn-mNoPrS3',
    name: 'Volleyball',
    capacity: 16,
    description: 'Bump, set, and spike your way to victory in a friendly game of volleyball.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity hammockTime = PrincipalActivity(
    id: 'hammock_time-principal_activity-brn-nOpQrT4',
    name: 'Hammock Time',
    capacity: 12,
    description: 'Relax and swing in a hammock with a good book or good company.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity lowRopes = PrincipalActivity(
    id: 'low_ropes-principal_activity-brn-oPqRsU5',
    name: 'Low Ropes',
    capacity: 14,
    description: 'Work with your team to navigate a series of challenges on a low ropes course.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity birdWatching = PrincipalActivity(
    id: 'bird_watching-principal_activity-brn-pQrStV6',
    name: 'Bird Watching',
    capacity: 16,
    description: 'Grab some binoculars and see how many different kinds of birds you can spot.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity planes = PrincipalActivity(
    id: 'planes-principal_activity-brn-qRsTuW7',
    name: 'Paper Planes',
    capacity: 17,
    description: 'Fold paper airplanes and see whose can fly the farthest or do the coolest tricks.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity origami = PrincipalActivity(
    id: 'origami-principal_activity-brn-rStUvX8',
    name: 'Origami',
    capacity: 17,
    description: 'Learn the Japanese art of paper folding to create beautiful and intricate designs.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity rockArt = PrincipalActivity(
    id: 'rock_art-principal_activity-brn-sTuVwY9',
    name: 'Rock Art',
    capacity: 16,
    description: 'Find cool rocks and paint them to look like animals, characters, or anything you can imagine.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity parachuteGames = PrincipalActivity(
    id: 'parachute_games-principal_activity-brn-tUvWxZ0',
    name: 'Parachute Games',
    capacity: 16,
    description: 'Work together to make waves, play games, and have fun with a giant parachute.',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity painting = PrincipalActivity(
    id: 'painting-principal_activity-brn-uVwXyA1',
    name: 'Painting',
    capacity: 17,
    description: 'Express your creativity with paints and a canvas to create your own masterpiece.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity bingo = PrincipalActivity(
    id: 'bingo-principal_activity-brn-vWxYzB2',
    name: 'Bingo',
    capacity: 17,
    description: 'A classic game of chance where you try to be the first to get five in a row.',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity natureHike = PrincipalActivity(
    id: 'nature_hike-principal_activity-brn-wXyZaC3',
    name: 'Nature Hike',
    capacity: 16,
    description: 'Explore the trails, learn about local plants and animals, and enjoy the beauty of nature.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity fieldGames = PrincipalActivity(
    id: 'field_games-principal_activity-brn-xYzAbD4',
    name: 'Field Games',
    capacity: 16,
    description: 'Play a variety of fun and active games out on the field with your friends.',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity hidingFromAuthority = PrincipalActivity(
    id: 'hiding_from_authority-principal_activity-brn-yZaBcE5',
    name: 'Hiding From Authority',
    capacity: 16,
    description: 'Camouflage yourself in ivy and sneak around camp. Try not to get spotted by any authority!',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity cardGamesDND = PrincipalActivity(
    id: 'card_games_dnd-principal_activity-brn-zAbCdF6',
    name: 'Card Games & DND',
    capacity: 16,
    description: 'Play a variety of card games or embark on an adventure in the world of Dungeons and Dragons.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity aggressiveCompliments = PrincipalActivity(
    id: 'aggressive_compliments-principal_activity-brn-zBbCdF6',
    name: 'Aggressive Compliments',
    capacity: 16,
    description: 'YOU ARE SO GOSH DARN GOOD AT RANKING ACTIVITIES!!!',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity fairyHouses = PrincipalActivity(
    id: 'fairy_houses-principal_activity-brn-zCbCdF6',
    name: 'Fairy Houses',
    capacity: 16,
    description: 'Ever wondered what happens when you build tiny houses out of sticks and leaves and leave them alone in the forrest?',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity teenSkillsRec = PrincipalActivity(
    id: 'teen_skills_rec-principal_activity-brn-zDbCdF6',
    name: 'Teen Skills',
    capacity: 19,
    description: 'Placeholder for whatever the teens are doing.',
    isSkillsRec: true,
    category: ActivityCategory.hidden,
  );

  static final PrincipalActivity bugBingo = PrincipalActivity(
    id: 'bug_bingo-principal_activity-brn-aBcDeF7',
    name: 'Bug Bingo',
    capacity: 16,
    description: 'Go on a bug hunt and see how many different kinds you can find to fill up your bingo card. The first to get five in a row wins!',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity badminton = PrincipalActivity(
    id: 'badminton-principal_activity-brn-aBcDeF7',
    name: 'Badminton',
    capacity: 16,
    description: 'Badminton is a racquet sport played using racquets to hit a shuttlecock across a net',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity outdoorLivingSkills = PrincipalActivity(
    id: 'outdoor_living_skills-principal_activity-brn-bCdEfG8',
    name: 'Outdoor Living Skills',
    capacity: 16,
    description: 'Learn essential survival skills like building a shelter and finding your way in the wilderness. Get ready for an adventure!',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity outdoorLivingSkillsSkills = PrincipalActivity(
    id: 'outdoor_living_skills-principal_activity-brn-bCwEfG8',
    name: 'Outdoor Living Skills',
    capacity: 16,
    description: 'Learn essential survival skills like building a shelter and finding your way in the wilderness. Get ready for an adventure!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity stackingAndSkipping = PrincipalActivity(
    id: 'stacking_and_skipping-principal_activity-brn-cDeFgH9',
    name: 'Stacking And Skipping',
    capacity: 16,
    description: 'Hang out at the beach. See who can stack rocks the highest, and who can skip rocks the furthest!',
    isSkillsRec: false,
    category: ActivityCategory.waterfront,
  );

  static final PrincipalActivity skitShow = PrincipalActivity(
    id: 'skit_show-principal_activity-brn-dEfGhI0',
    name: 'Skit Show',
    capacity: 16,
    description: 'Let your creativity shine as you write and perform your own hilarious skits. Get ready to put on a show!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity paperCrafts = PrincipalActivity(
    id: 'paper_crafts-principal_activity-brn-eFgHiJ1',
    name: 'Paper Crafts',
    capacity: 16,
    description: 'From origami to paper airplanes, learn how to fold and create amazing things with just a few pieces of paper. Let your imagination soar!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity stationary = PrincipalActivity(
    id: 'stationary-principal_activity-brn-fGhIjK2',
    name: 'Stationary',
    capacity: 16,
    description: 'Design your own personalized stationery to send letters to your friends and family. Get creative and make your mail extra special!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity magicTheGathering = PrincipalActivity(
    id: 'magic_the_gathering-principal_activity-brn-gHiJkL3',
    name: 'Magic The Gathering',
    capacity: 16,
    description: 'Learn to play the popular trading card game, Magic: The Gathering. Build your deck, challenge your friends, and become a master strategist!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity waterTasting = PrincipalActivity(
    id: 'water_tasting-principal_activity-brn-hIjKlM4',
    name: 'Water Tasting',
    capacity: 16,
    description: 'Do you think all water tastes the same? Put your taste buds to the test and see if you can tell the difference between different types of water at camp.',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity tagGames = PrincipalActivity(
    id: 'tag_games-principal_activity-brn-iJkLmN5',
    name: 'Tag Games',
    capacity: 16,
    description: 'Get ready to run, dodge, and chase your friends in a variety of classic tag games. It\'s a great way to have fun and get some exercise!',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity boxSitting = PrincipalActivity(
    id: 'box_sitting-principal_activity-brn-jKlMnO6',
    name: 'Box Sitting',
    capacity: 16,
    description: 'Grab a box, decorate it, sit in it. It might sound strange, but you\'d be surprised how fun it can be!',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity nappingSpots = PrincipalActivity(
    id: 'napping_spots-principal_activity-brn-kLmNoP7',
    name: 'Napping Spots',
    capacity: 16,
    description: 'Join us on a quest to find the coziest and most peaceful napping spots around camp.',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity riddlesAndGames = PrincipalActivity(
    id: 'riddles_and_games-principal_activity-brn-lMnOqR8',
    name: 'Riddles And Games',
    capacity: 16,
    description: 'Put your thinking cap on and get ready to solve some brain-teasing riddles and play some fun games. It\'s a great way to challenge your mind!',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity fuseBeads = PrincipalActivity(
    id: 'fuse_beads-principal_activity-brn-mNoPrS9',
    name: 'Fuse Beads',
    capacity: 16,
    description: 'Create colorful and unique designs with fuse beads. Arrange the beads on a pegboard, and we\'ll iron them together to create a permanent masterpiece!',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity safetyPatrol = PrincipalActivity(
    id: 'safety_patrol-principal_activity-brn-nOpQrT0',
    name: 'Safety Patrol',
    capacity: 16,
    description: 'Catch all the safety violations at camp and give them a ticket!',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity gagaBallTournament = PrincipalActivity(
    id: 'gaga_ball_tournament-principal_activity-brn-oPqRsU1',
    name: 'Gaga Ball Tournament',
    capacity: 16,
    description: 'Compete against your fellow campers in an epic gaga ball tournament. Do you have what it takes to be crowned the gaga champion?',
    isSkillsRec: false,
    category: ActivityCategory.sportsAndAthletics,
  );

  static final PrincipalActivity artInNature = PrincipalActivity(
    id: 'art_in_nature-principal_activity-brn-pQrStV2',
    name: 'Art In Nature',
    capacity: 16,
    description: 'Use the natural world as your inspiration and your art supply! Create beautiful works of art using leaves, flowers, twigs, and other materials you find in nature.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity something = PrincipalActivity(
    id: 'something-principal_activity-brn-pQrstV2',
    name: 'Something',
    capacity: 1000,
    description: 'A placeholder',
    isSkillsRec: false,
    category: ActivityCategory.hidden,
  );

  static final PrincipalActivity somethingSkills = PrincipalActivity(
    id: 'something-principal_activity-brn-pQestV2',
    name: 'Something',
    capacity: 1000,
    description: 'A placeholder',
    isSkillsRec: true,
    category: ActivityCategory.hidden,
  );

  static final PrincipalActivity natureFigures = PrincipalActivity(
    id: 'nature_figures-principal_activity-brn-pQestV3',
    name: 'Nature Figures',
    capacity: 16,
    description: 'Learn how to craft small figures out of nature.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity highV = PrincipalActivity(
    id: 'high_v-principal_activity-brn-pQes4V3',
    name: 'High V',
    capacity: 12,
    description: 'Support your friends and work together to traverse the high V.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity decoupageTiles = PrincipalActivity(
    id: 'decoupage_tiles-principal_activity-brn-pres4V3',
    name: 'Decoupage Tiles',
    capacity: 17,
    description: 'Learn the art of decoupage by decorating ceramic tiles.',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity posterMaking = PrincipalActivity(
    id: 'poster_making-principal_activity-brn-p0sTeR1',
    name: 'Poster Making',
    capacity: 17,
    description: 'Unleash your creativity and design eye-catching posters. Whether it\'s for an event, a cause, or just for fun, you\'ll learn techniques to make your message stand out.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity dnd = PrincipalActivity(
    id: 'dungeons_and_dragons-principal_activity-brn-dNdSuFf',
    name: 'Dungeons And Dragons',
    capacity: 17,
    description: 'Embark on epic quests, battle mythical creatures, and weave your own fantasy story in the world of Dungeons and Dragons. No experience necessary!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity artInNatureSkills = PrincipalActivity(
    id: 'art_in_nature_skills-principal_activity-brn-aRtN4tU',
    name: 'Art In Nature',
    capacity: 17,
    description: 'Learn to use natural materials like leaves, twigs, stones, and flowers to create beautiful and unique works of art. Discover your inner artist in the great outdoors.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity readingClub = PrincipalActivity(
    id: 'reading_club-principal_activity-brn-aRtu4tU',
    name: 'Reading Club',
    capacity: 16,
    description: 'Bring your favorite book and a blanket and find a cozy spot to read. Share what you\'re reading with others!',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity circleOfLife = PrincipalActivity(
    id: 'circle_of_life-principal_activity-brn-aRYN4tU',
    name: 'Circle of Life',
    capacity: 16,
    description: '',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );

  static final PrincipalActivity paintTheCounselor = PrincipalActivity(
    id: 'paint_the_counselor-principal_activity-brn-aRYo4tU',
    name: 'Paint the Counselor',
    capacity: 16,
    description: 'Your favorite counselors have volunteered to be human canvases. Use washable paints to turn them into colorful masterpieces.',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity chess = PrincipalActivity(
    id: 'chess-principal_activity-brn-cH3sSa1',
    name: 'Chess',
    capacity: 16,
    description: 'Learn the classic game of strategy and tactics. Challenge your friends to a match and work on your checkmate!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity languageLearning = PrincipalActivity(
    id: 'language_learning-principal_activity-brn-lnGu4G3',
    name: 'Language Learning',
    capacity: 16,
    description: 'Learn the basics of a new language through fun games and activities. ¡Vamos!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity rugby = PrincipalActivity(
    id: 'rugby-principal_activity-brn-oPqRst1',
    name: 'Rugby',
    capacity: 16,
    description: 'Learn the fundamentals of rugby, including passing, tackling, and the rules of the game, in a safe and fun environment.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity dance = PrincipalActivity(
    id: 'dance-principal_activity-brn-o2qRst1',
    name: 'Dance',
    capacity: 16,
    description: 'Learn new moves, choreograph routines, and express yourself through movement. All skill levels are welcome!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity comicBookCreation = PrincipalActivity(
    id: 'comic_book_creation-principal_activity-brn-o2ERst1',
    name: 'Comic Book Creation',
    capacity: 16,
    description: 'Create your own characters, write a storyline, and learn to draw and panel your very own comic book. Bring your ideas to life!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity graffitiWall = PrincipalActivity(
    id: 'graffiti_wall-principal_activity-brn-gWa1lA1',
    name: 'Graffiti Wall',
    capacity: 16,
    description: 'Express yourself on our designated graffiti wall. Grab some paint and unleash your inner street artist!',
    isSkillsRec: false,
    category: ActivityCategory.creative,
  );

  static final PrincipalActivity snorkeling = PrincipalActivity(
    id: 'snorkeling-principal_activity-brn-sN0rKe1',
    name: 'Snorkeling',
    capacity: 12,
    description: 'Explore the underwater world of the Puget Sound. See fish and other marine life up close!',
    isSkillsRec: false,
    category: ActivityCategory.waterfront,
  );

  static final PrincipalActivity aussieAussieAussie = PrincipalActivity(
    id: 'aussie_aussie_aussie-principal_activity-brn-aUs1eA1',
    name: 'Aussie Aussie Aussie',
    capacity: 16,
    description: 'Learn about Australian culture, from slang to sports, with our counselors from down under!',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity journaling = PrincipalActivity(
    id: 'journaling-principal_activity-brn-j0uRnA1',
    name: 'Journaling',
    capacity: 16,
    description: 'Take some time for quiet reflection. We\'ll provide the journals and pens, you provide the thoughts.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity magicBehindAirplanes = PrincipalActivity(
    id: 'magic_behind_airplanes-principal_activity-brn-mAg1cB3',
    name: 'The Magic Behind Airplanes',
    capacity: 16,
    description: 'Learn about the science of flight and build your own model airplane.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity cardAndBoardGames = PrincipalActivity(
    id: 'card_and_board_games-principal_activity-brn-c4rDb04',
    name: 'Card & Board Games',
    capacity: 16,
    description: 'Learn to play a variety of card and board games, from classics to modern hits.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity singingChoir = PrincipalActivity(
    id: 'singing_choir-principal_activity-brn-s1nGcH0',
    name: 'Singing / Choir',
    capacity: 16,
    description: 'Learn to sing in a group and perform a song together.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity kickball = PrincipalActivity(
    id: 'kickball-principal_activity-brn-k1cKb41',
    name: 'Kickball',
    capacity: 16,
    description: 'Play a game of kickball with your friends.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity drawing = PrincipalActivity(
    id: 'drawing-principal_activity-brn-d4w1nG4',
    name: 'Drawing',
    capacity: 16,
    description: 'Learn the fundamentals of drawing and create your own works of art.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity selfCare = PrincipalActivity(
    id: 'self_care-principal_activity-brn-s31Fc4r',
    name: 'Self-Care',
    capacity: 16,
    description: 'Learn about the importance of self-care and practice techniques to help you relax and de-stress.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity fashionDesign = PrincipalActivity(
    id: 'fashion_design-principal_activity-brn-f4sh10n',
    name: 'Fashion Design',
    capacity: 16,
    description: 'Design and create your own fashion pieces. Learn about color, patterns, and style.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity calisthenics = PrincipalActivity(
    id: 'calisthenics-principal_activity-brn-c4l1sth',
    name: 'Calisthenics',
    capacity: 16,
    description: 'Build strength and fitness using your own body weight through exercises like push-ups, pull-ups, and squats.',
    isSkillsRec: true,
    category: ActivityCategory.skills,
  );

  static final PrincipalActivity livingLikeFarcus = PrincipalActivity(
    id: 'living_like_farcus-principal_activity-brn-f4rcUs1',
    name: 'Living like Farcus',
    capacity: 16,
    description: '',
    isSkillsRec: false,
    category: ActivityCategory.silly,
  );

  static final PrincipalActivity carWashClub = PrincipalActivity(
    id: 'car_wash_club-principal_activity-brn-c4rW4sh',
    name: 'Car Wash Club',
    capacity: 16,
    description: 'Help clean the camp vehicles while having fun with soap, water, and your friends.',
    isSkillsRec: false,
    category: ActivityCategory.campClassics,
  );
}