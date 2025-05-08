/// A very basic “blocklist” filter.
/// Expand `_bannedWords` as needed.
class SimpleFilter {
  static final Set<String> _bannedWords = {
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'cock',
    'dick',
    'pussy',
    'nigger',
    'whore',
    'slut',
    'bastard',
    'fag',
    'dyke',
    // Hate speech or discriminatory language
    'terrorist',
    'racist',
    'sexist',
    'bigot',
    'xenophobe',
    'homophobe',
    'anti-semitic',

    // Abuse or violence-related terms
    'rape',
    'kill',
    'murder',
    'shoot',
    'bomb',
    'suicide',
    // Drugs and explicit substances
    'heroin',
    'meth',
    'crack',
    'weed',
    'cocaine',

    // Derogatory terms and slurs
    'retard',
    'cripple',
    'idiot',
    'moron',
    'stupid',

    // Explicit content
    'porn',
    'sex',
    'boobs',
    'tits',
    'fistfuck',
    // Other offensive or inappropriate terms
    'kike', // derogatory term for Jewish people
    'gook', // derogatory term for Asian people
    'chink', // derogatory term for Chinese people
    'spic', // derogatory term for Latinx people
    'sandnigger', // derogatory term for people of Middle Eastern descent
    'wetback', // derogatory term for Mexican people
    'tranny', // derogatory term for transgender individuals

    // add more disallowed terms here…
  };

  /// Returns true if [text] does *not* contain any banned word.
  static bool isClean(String text) {
    final words =
        text.toLowerCase().split(RegExp(r'\W+')); // split on non-word chars
    for (var w in words) {
      if (_bannedWords.contains(w)) {
        return false;
      }
    }
    return true;
  }
}
