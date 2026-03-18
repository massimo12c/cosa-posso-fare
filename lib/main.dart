import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CosaPossoFareApp());
}

class CosaPossoFareApp extends StatelessWidget {
  const CosaPossoFareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cosa posso fare',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const HomePage(),
    );
  }
}

class Categoria {
  final String titolo;
  final String emoji;
  final IconData icona;
  final Color colore;

  const Categoria({
    required this.titolo,
    required this.emoji,
    required this.icona,
    required this.colore,
  });
}

const List<Categoria> categorie = [
  Categoria(
    titolo: 'Cucina',
    emoji: '🍝',
    icona: Icons.restaurant_menu,
    colore: Color(0xFFFFA726),
  ),
  Categoria(
    titolo: 'Allenamento',
    emoji: '🏋️',
    icona: Icons.fitness_center,
    colore: Color(0xFF66BB6A),
  ),
  Categoria(
    titolo: 'Fai-da-te',
    emoji: '🛠️',
    icona: Icons.handyman,
    colore: Color(0xFF8D6E63),
  ),
  Categoria(
    titolo: 'Lavoro',
    emoji: '💰',
    icona: Icons.work,
    colore: Color(0xFF42A5F5),
  ),
  Categoria(
    titolo: 'Hobby',
    emoji: '🎨',
    icona: Icons.palette,
    colore: Color(0xFFEC407A),
  ),
  Categoria(
    titolo: 'Pulizie',
    emoji: '🧹',
    icona: Icons.cleaning_services,
    colore: Color(0xFF26C6DA),
  ),
  Categoria(
    titolo: 'Tempo libero',
    emoji: '❤️',
    icona: Icons.weekend,
    colore: Color(0xFF7E57C2),
  ),
];

Categoria categoriaDaTitolo(String titolo) {
  return categorie.firstWhere(
    (c) => c.titolo == titolo,
    orElse: () => categorie.first,
  );
}

class Idea {
  final String titolo;
  final String descrizione;
  final String tempo;
  final String difficolta;
  final String serve;
  final String comeFare;
  final String googleQuery;
  final String youtubeQuery;

  const Idea({
    required this.titolo,
    required this.descrizione,
    required this.tempo,
    required this.difficolta,
    required this.serve,
    required this.comeFare,
    required this.googleQuery,
    required this.youtubeQuery,
  });

  Map<String, dynamic> toMap() {
    return {
      'titolo': titolo,
      'descrizione': descrizione,
      'tempo': tempo,
      'difficolta': difficolta,
      'serve': serve,
      'comeFare': comeFare,
      'googleQuery': googleQuery,
      'youtubeQuery': youtubeQuery,
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    return Idea(
      titolo: map['titolo'] ?? '',
      descrizione: map['descrizione'] ?? '',
      tempo: map['tempo'] ?? '',
      difficolta: map['difficolta'] ?? '',
      serve: map['serve'] ?? '',
      comeFare: map['comeFare'] ?? '',
      googleQuery: map['googleQuery'] ?? '',
      youtubeQuery: map['youtubeQuery'] ?? '',
    );
  }
}

class IdeaPreferita {
  final String categoria;
  final Idea idea;

  const IdeaPreferita({
    required this.categoria,
    required this.idea,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoria': categoria,
      'idea': idea.toMap(),
    };
  }

  factory IdeaPreferita.fromMap(Map<String, dynamic> map) {
    return IdeaPreferita(
      categoria: map['categoria'] ?? '',
      idea: Idea.fromMap(Map<String, dynamic>.from(map['idea'] ?? {})),
    );
  }
}

Future<void> apriRicercaGoogle(String testo) async {
  final query = Uri.encodeComponent(testo);
  final url = Uri.parse('https://www.google.com/search?q=$query');
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication);

  if (!ok) {
    throw Exception('Impossibile aprire Google');
  }
}

Future<void> apriRicercaYouTube(String testo) async {
  final query = Uri.encodeComponent(testo);
  final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication);

  if (!ok) {
    throw Exception('Impossibile aprire YouTube');
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<IdeaPreferita> preferiti = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    caricaPreferiti();
  }

  Future<void> caricaPreferiti() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('preferiti') ?? [];

    preferiti
      ..clear()
      ..addAll(
        saved.map((e) {
          final map = jsonDecode(e) as Map<String, dynamic>;
          return IdeaPreferita.fromMap(map);
        }),
      );

    setState(() {
      loading = false;
    });
  }

  Future<void> salvaPreferiti() async {
    final prefs = await SharedPreferences.getInstance();
    final data = preferiti.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('preferiti', data);
  }

  Future<void> togglePreferito(String categoria, Idea idea) async {
    final esiste = preferiti.any(
      (p) => p.categoria == categoria && p.idea.titolo == idea.titolo,
    );

    setState(() {
      if (esiste) {
        preferiti.removeWhere(
          (p) => p.categoria == categoria && p.idea.titolo == idea.titolo,
        );
      } else {
        preferiti.add(IdeaPreferita(categoria: categoria, idea: idea));
      }
    });

    await salvaPreferiti();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosa posso fare'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreferitiPage(
                    preferiti: preferiti,
                    onTogglePreferito: togglePreferito,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite),
                if (preferiti.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${preferiti.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versione completa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scrivi ingredienti, nome ricetta, obiettivo o problema. Puoi usare anche il microfono.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                itemCount: categorie.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.02,
                ),
                itemBuilder: (context, index) {
                  final categoria = categorie[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InputPage(
                            categoria: categoria,
                            preferiti: preferiti,
                            onTogglePreferito: togglePreferito,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: categoria.colore.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: categoria.colore.withOpacity(0.30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  categoria.colore.withOpacity(0.20),
                              child: Icon(
                                categoria.icona,
                                color: categoria.colore,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              categoria.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              categoria.titolo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InputPage extends StatefulWidget {
  final Categoria categoria;
  final List<IdeaPreferita> preferiti;
  final Future<void> Function(String categoria, Idea idea) onTogglePreferito;

  const InputPage({
    super.key,
    required this.categoria,
    required this.preferiti,
    required this.onTogglePreferito,
  });

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController controller = TextEditingController();
  final stt.SpeechToText speech = stt.SpeechToText();

  bool ascoltando = false;
  bool speechDisponibile = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> toggleMicrofono() async {
    if (ascoltando) {
      await speech.stop();
      setState(() => ascoltando = false);
      return;
    }

    final disponibile = await speech.initialize();
    if (!disponibile) {
      setState(() => speechDisponibile = false);
      return;
    }

    setState(() {
      ascoltando = true;
      speechDisponibile = true;
    });

    speech.listen(
      localeId: 'it_IT',
      onResult: (result) {
        setState(() {
          controller.text = result.recognizedWords;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        });
      },
    );
  }

  String get hint {
    switch (widget.categoria.titolo) {
      case 'Cucina':
        return 'Es. tiramisu / carbonara / ho uova, latte e farina';
      case 'Allenamento':
        return 'Es. 10 minuti, addominali, principiante';
      case 'Fai-da-te':
        return 'Es. mensola, buco nel muro, legno, cartongesso';
      case 'Lavoro':
        return 'Es. guadagnare da casa, clienti, poco budget';
      case 'Hobby':
        return 'Es. creativo, rilassante, manuale';
      case 'Pulizie':
        return 'Es. bagno sporco, cucina, riordinare, 15 minuti';
      case 'Tempo libero':
        return 'Es. sono solo, con amici, spendere poco';
      default:
        return 'Scrivi qui';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria = widget.categoria;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoria.titolo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: categoria.colore.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: categoria.colore.withOpacity(0.20),
                    child: Icon(
                      categoria.icona,
                      color: categoria.colore,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${categoria.emoji} ${categoria.titolo}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Scrivi in modo dettagliato',
                hintText: hint,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                suffixIcon: IconButton(
                  onPressed: toggleMicrofono,
                  icon: Icon(
                    ascoltando ? Icons.mic : Icons.mic_none,
                    color: ascoltando ? Colors.red : Colors.deepPurple,
                  ),
                ),
              ),
            ),
            if (!speechDisponibile)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Microfono non disponibile su questo dispositivo/browser.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RisultatiPage(
                        categoria: categoria,
                        input: controller.text.trim(),
                        preferiti: widget.preferiti,
                        onTogglePreferito: widget.onTogglePreferito,
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Trova idee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoria.colore,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RisultatiPage extends StatefulWidget {
  final Categoria categoria;
  final String input;
  final List<IdeaPreferita> preferiti;
  final Future<void> Function(String categoria, Idea idea) onTogglePreferito;

  const RisultatiPage({
    super.key,
    required this.categoria,
    required this.input,
    required this.preferiti,
    required this.onTogglePreferito,
  });

  @override
  State<RisultatiPage> createState() => _RisultatiPageState();
}

class _RisultatiPageState extends State<RisultatiPage> {
  bool isPreferito(Idea idea) {
    return widget.preferiti.any(
      (p) =>
          p.categoria == widget.categoria.titolo &&
          p.idea.titolo == idea.titolo,
    );
  }

  void mostraDettagli(Idea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.titolo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                infoRiga('Tempo', idea.tempo),
                infoRiga('Difficoltà', idea.difficolta),
                infoRiga('Ti serve', idea.serve),
                const SizedBox(height: 14),
                const Text(
                  'Come fare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  idea.comeFare,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => apriRicercaGoogle(idea.googleQuery),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Cerca su Google'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => apriRicercaYouTube(idea.youtubeQuery),
                    icon: const Icon(Icons.smart_display),
                    label: const Text('Cerca su YouTube'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget infoRiga(String titolo, String valore) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: '$titolo: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valore),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idee = generaIdee(widget.categoria.titolo, widget.input);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risultati'),
      ),
      body: idee.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Non ho trovato qualcosa di preciso. Prova a scrivere più dettagli, per esempio ingredienti, nome ricetta, tempo, livello o obiettivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: idee.length,
              itemBuilder: (context, index) {
                final idea = idee[index];
                final preferita = isPreferito(idea);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                idea.titolo,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await widget.onTogglePreferito(
                                  widget.categoria.titolo,
                                  idea,
                                );
                                setState(() {});
                              },
                              icon: Icon(
                                preferita
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: preferita ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          idea.descrizione,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            chipInfo('⏱ ${idea.tempo}'),
                            chipInfo('📌 ${idea.difficolta}'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => mostraDettagli(idea),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.categoria.colore,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Dettagli'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    apriRicercaGoogle(idea.googleQuery),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Google'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                apriRicercaYouTube(idea.youtubeQuery),
                            icon: const Icon(Icons.smart_display),
                            label: const Text('YouTube'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget chipInfo(String testo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        testo,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class PreferitiPage extends StatelessWidget {
  final List<IdeaPreferita> preferiti;
  final Future<void> Function(String categoria, Idea idea) onTogglePreferito;

  const PreferitiPage({
    super.key,
    required this.preferiti,
    required this.onTogglePreferito,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferiti'),
      ),
      body: preferiti.isEmpty
          ? const Center(
              child: Text(
                'Non hai ancora salvato nulla.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: preferiti.length,
              itemBuilder: (context, index) {
                final item = preferiti[index];
                final cat = categoriaDaTitolo(item.categoria);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.colore.withOpacity(0.15),
                      child: Text(cat.emoji),
                    ),
                    title: Text(
                      item.idea.titolo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        Text('${item.categoria} • ${item.idea.descrizione}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              apriRicercaGoogle(item.idea.googleQuery),
                          icon: const Icon(Icons.open_in_new),
                        ),
                        IconButton(
                          onPressed: () =>
                              apriRicercaYouTube(item.idea.youtubeQuery),
                          icon: const Icon(Icons.smart_display),
                        ),
                        IconButton(
                          onPressed: () async {
                            await onTogglePreferito(item.categoria, item.idea);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

List<Idea> generaIdee(String categoria, String testoOriginale) {
  final testo = testoOriginale.toLowerCase().trim();
  final idee = <Idea>[];

  bool ha(String parola) => testo.contains(parola);

  if (categoria == 'Cucina') {
    if (ha('tiramisu')) {
      idee.add(
        const Idea(
          titolo: 'Tiramisù',
          descrizione:
              'Hai scritto tiramisù, quindi ti propongo direttamente questa ricetta classica.',
          tempo: '30 minuti + riposo',
          difficolta: 'Media',
          serve: 'Mascarpone, uova, zucchero, savoiardi, caffè, cacao',
          comeFare:
              'Prepara il caffè e fallo raffreddare. Monta i tuorli con lo zucchero, aggiungi il mascarpone e mescola. Bagna velocemente i savoiardi nel caffè, fai gli strati con la crema e termina con cacao amaro. Lascia riposare in frigo.',
          googleQuery: 'tiramisu ricetta',
          youtubeQuery: 'tiramisu ricetta video',
        ),
      );
    }

    if (ha('carbonara')) {
      idee.add(
        const Idea(
          titolo: 'Pasta alla carbonara',
          descrizione:
              'Hai chiesto la carbonara, quindi vado diretto con questa ricetta.',
          tempo: '20 minuti',
          difficolta: 'Media',
          serve: 'Pasta, uova, pecorino, guanciale, pepe',
          comeFare:
              'Cuoci la pasta. Rosola il guanciale. Mescola uova, pecorino e pepe in una ciotola. Unisci la pasta al guanciale e poi aggiungi la crema di uova lontano dal fuoco, mescolando velocemente.',
          googleQuery: 'carbonara ricetta originale',
          youtubeQuery: 'carbonara ricetta video',
        ),
      );
    }

    if (ha('pancake')) {
      idee.add(
        const Idea(
          titolo: 'Pancake',
          descrizione: 'Hai chiesto pancake, quindi ti propongo la ricetta base.',
          tempo: '15 minuti',
          difficolta: 'Facile',
          serve: 'Farina, latte, uova, zucchero, lievito',
          comeFare:
              'Mescola gli ingredienti fino a ottenere un impasto liscio. Versa poco composto alla volta in padella antiaderente e cuoci su entrambi i lati.',
          googleQuery: 'pancake ricetta facile',
          youtubeQuery: 'pancake ricetta video',
        ),
      );
    }

    if (ha('pizza')) {
      idee.add(
        const Idea(
          titolo: 'Pizza semplice',
          descrizione:
              'Hai scritto pizza, quindi ti propongo una versione base fatta in casa.',
          tempo: '20 minuti + lievitazione',
          difficolta: 'Media',
          serve: 'Farina, acqua, lievito, sale, pomodoro, mozzarella',
          comeFare:
              'Prepara l’impasto con farina, acqua, lievito e sale. Lascialo lievitare, stendilo, aggiungi pomodoro e mozzarella e cuoci in forno molto caldo.',
          googleQuery: 'pizza fatta in casa ricetta',
          youtubeQuery: 'pizza fatta in casa video',
        ),
      );
    }

    if (ha('frittata')) {
      idee.add(
        const Idea(
          titolo: 'Frittata',
          descrizione:
              'Hai chiesto una frittata, quindi ti propongo la versione base.',
          tempo: '10 minuti',
          difficolta: 'Facile',
          serve: 'Uova, sale, olio, eventuale formaggio o verdure',
          comeFare:
              'Sbatti le uova con sale, aggiungi formaggio o verdure se vuoi, versa in padella con poco olio e cuoci a fuoco medio.',
          googleQuery: 'frittata ricetta facile',
          youtubeQuery: 'frittata ricetta video',
        ),
      );
    }

    if (ha('bruschette')) {
      idee.add(
        const Idea(
          titolo: 'Bruschette',
          descrizione: 'Hai chiesto bruschette, quindi ti do la ricetta base.',
          tempo: '10 minuti',
          difficolta: 'Facile',
          serve: 'Pane, pomodoro, olio, sale, origano',
          comeFare:
              'Tosta il pane, taglia il pomodoro a pezzetti e condiscilo con olio, sale e origano. Metti il composto sopra il pane e servi.',
          googleQuery: 'bruschette ricetta',
          youtubeQuery: 'bruschette ricetta video',
        ),
      );
    }

    if (ha('toast')) {
      idee.add(
        const Idea(
          titolo: 'Toast',
          descrizione:
              'Hai scritto toast, quindi vado con una versione semplice e veloce.',
          tempo: '8 minuti',
          difficolta: 'Facile',
          serve: 'Pane, formaggio, prosciutto facoltativo',
          comeFare:
              'Metti formaggio tra due fette di pane, aggiungi prosciutto se vuoi e scalda in piastra o padella fino a doratura.',
          googleQuery: 'toast ricetta',
          youtubeQuery: 'toast ricetta video',
        ),
      );
    }

    if (ha('uova') && ha('farina') && ha('latte')) {
      idee.add(
        const Idea(
          titolo: 'Pancake',
          descrizione:
              'Hai una combinazione perfetta per fare pancake fatti in casa.',
          tempo: '15 minuti',
          difficolta: 'Facile',
          serve: 'Uova, farina, latte, padella',
          comeFare:
              'Mescola uova, farina e latte fino a ottenere un composto liscio. Versa poco impasto alla volta in padella calda e cuoci da entrambi i lati.',
          googleQuery: 'pancake ricetta facile',
          youtubeQuery: 'pancake ricetta video',
        ),
      );
    }

    if (ha('uova') && ha('patate')) {
      idee.add(
        const Idea(
          titolo: 'Frittata di patate',
          descrizione:
              'Se hai uova e patate puoi fare un piatto semplice e sostanzioso.',
          tempo: '25 minuti',
          difficolta: 'Facile',
          serve: 'Uova, patate, olio, padella',
          comeFare:
              'Taglia le patate sottili, falle cuocere in padella con poco olio, poi versa sopra le uova sbattute e cuoci bene la frittata.',
          googleQuery: 'frittata di patate ricetta',
          youtubeQuery: 'frittata di patate video',
        ),
      );
    }

    if (ha('uova') && ha('formaggio')) {
      idee.add(
        const Idea(
          titolo: 'Frittata al formaggio',
          descrizione:
              'Se hai uova e formaggio puoi fare qualcosa di rapido e buono.',
          tempo: '10 minuti',
          difficolta: 'Facile',
          serve: 'Uova, formaggio, sale, padella',
          comeFare:
              'Sbatti le uova, aggiungi il formaggio, versa in padella e cuoci a fuoco medio finché la frittata è pronta.',
          googleQuery: 'frittata al formaggio ricetta',
          youtubeQuery: 'frittata al formaggio video',
        ),
      );
    }

    if (ha('tonno') && ha('pasta')) {
      idee.add(
        const Idea(
          titolo: 'Pasta al tonno',
          descrizione:
              'Hai tonno e pasta: ottima base per un primo veloce.',
          tempo: '15 minuti',
          difficolta: 'Facile',
          serve: 'Pasta, tonno, olio, padella',
          comeFare:
              'Cuoci la pasta. In padella metti olio e tonno. Scola la pasta e saltala insieme al tonno. Se vuoi, aggiungi pomodoro.',
          googleQuery: 'pasta al tonno ricetta',
          youtubeQuery: 'pasta al tonno video',
        ),
      );
    }

    if (ha('pane') && ha('pomodoro')) {
      idee.add(
        const Idea(
          titolo: 'Bruschette',
          descrizione:
              'Con pane e pomodoro puoi fare qualcosa di semplice ma molto buono.',
          tempo: '10 minuti',
          difficolta: 'Facile',
          serve: 'Pane, pomodoro, olio, sale',
          comeFare:
              'Tosta il pane, condisci il pomodoro a pezzetti con olio e sale e mettilo sopra il pane.',
          googleQuery: 'bruschette pomodoro ricetta',
          youtubeQuery: 'bruschette pomodoro video',
        ),
      );
    }

    if (ha('pane') && ha('formaggio')) {
      idee.add(
        const Idea(
          titolo: 'Toast o pane caldo al formaggio',
          descrizione:
              'Hai pane e formaggio: ottima base per qualcosa di veloce.',
          tempo: '8 minuti',
          difficolta: 'Facile',
          serve: 'Pane, formaggio, padella o piastra',
          comeFare:
              'Metti il formaggio tra due fette di pane oppure sopra il pane aperto e scalda finché il formaggio si scioglie bene.',
          googleQuery: 'toast al formaggio ricetta',
          youtubeQuery: 'toast al formaggio video',
        ),
      );
    }

    if (ha('veloce') || ha('rapido')) {
      idee.add(
        const Idea(
          titolo: 'Piatto veloce improvvisato',
          descrizione:
              'Hai chiesto qualcosa di rapido, quindi meglio pochi passaggi e ingredienti semplici.',
          tempo: '5-10 minuti',
          difficolta: 'Facile',
          serve: 'Ingredienti base già pronti',
          comeFare:
              'Scegli una base come pane, pasta o uova e abbinala a qualcosa di pronto come tonno, formaggio o pomodoro.',
          googleQuery: 'ricette veloci facili',
          youtubeQuery: 'ricette veloci facili video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Idea cucina base',
          descrizione:
              'Non ho trovato una corrispondenza precisa, ma posso comunque orientarti.',
          tempo: '10-20 minuti',
          difficolta: 'Facile',
          serve: 'Quello che hai scritto: $testoOriginale',
          comeFare:
              'Prova a scrivere il nome preciso della ricetta oppure gli ingredienti che hai.',
          googleQuery: '$testoOriginale ricetta',
          youtubeQuery: '$testoOriginale ricetta video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  if (categoria == 'Allenamento') {
    if (ha('10 minuti') || ha('10 min')) {
      idee.add(
        const Idea(
          titolo: 'Allenamento veloce 10 minuti',
          descrizione: 'Ideale se hai poco tempo ma vuoi comunque attivarti.',
          tempo: '10 minuti',
          difficolta: 'Facile-media',
          serve: 'Spazio libero',
          comeFare:
              'Fai 3 giri di squat, piegamenti facilitati, crunch e plank con pause brevi.',
          googleQuery: 'allenamento 10 minuti a casa',
          youtubeQuery: 'allenamento 10 minuti casa video',
        ),
      );
    }

    if (ha('addominali')) {
      idee.add(
        const Idea(
          titolo: 'Routine addominali',
          descrizione: 'Adatta se vuoi concentrarti sul core.',
          tempo: '12-15 minuti',
          difficolta: 'Media',
          serve: 'Tappetino facoltativo',
          comeFare:
              'Fai 3 giri di crunch, sollevamenti gambe, plank e russian twist.',
          googleQuery: 'allenamento addominali casa',
          youtubeQuery: 'allenamento addominali casa video',
        ),
      );
    }

    if (ha('principiante')) {
      idee.add(
        const Idea(
          titolo: 'Scheda principiante',
          descrizione:
              'Se sei all’inizio, meglio partire semplice ma con continuità.',
          tempo: '15 minuti',
          difficolta: 'Facile',
          serve: 'Spazio libero',
          comeFare:
              'Fai squat lenti, piegamenti al muro, ponte glutei e plank corto.',
          googleQuery: 'allenamento principiante casa',
          youtubeQuery: 'allenamento principiante casa video',
        ),
      );
    }

    if (ha('casa')) {
      idee.add(
        const Idea(
          titolo: 'Allenamento a casa',
          descrizione: 'Circuito base senza attrezzi.',
          tempo: '20 minuti',
          difficolta: 'Media',
          serve: 'Spazio libero',
          comeFare:
              'Alterna squat, affondi, piegamenti, jumping jack e plank in 4 giri.',
          googleQuery: 'allenamento a casa senza attrezzi',
          youtubeQuery: 'allenamento a casa senza attrezzi video',
        ),
      );
    }

    if (ha('dimagrire') || ha('bruciare')) {
      idee.add(
        const Idea(
          titolo: 'Circuito attivo per bruciare',
          descrizione: 'Utile se vuoi aumentare il ritmo.',
          tempo: '20 minuti',
          difficolta: 'Media',
          serve: 'Spazio libero e acqua',
          comeFare:
              'Fai 30 secondi per esercizio: jumping jack, squat, mountain climber e affondi. Ripeti 4 volte.',
          googleQuery: 'allenamento brucia grassi casa',
          youtubeQuery: 'allenamento brucia grassi casa video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Allenamento base completo',
          descrizione:
              'Ti propongo una base generale perché non hai dato dettagli precisi.',
          tempo: '15-20 minuti',
          difficolta: 'Media',
          serve: 'Spazio libero',
          comeFare:
              'Fai squat, piegamenti facilitati, plank, crunch e affondi in 3 o 4 giri.',
          googleQuery: '$testoOriginale allenamento',
          youtubeQuery: '$testoOriginale allenamento video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  if (categoria == 'Fai-da-te') {
    if (ha('mensola')) {
      idee.add(
        const Idea(
          titolo: 'Montare una mensola',
          descrizione: 'Lavoro utile e abbastanza semplice da organizzare.',
          tempo: '30-45 minuti',
          difficolta: 'Media',
          serve: 'Mensola, tasselli, trapano, livella',
          comeFare:
              'Segna i punti, controlla la livella, fora, inserisci i tasselli e monta i supporti.',
          googleQuery: 'come montare una mensola',
          youtubeQuery: 'come montare una mensola video',
        ),
      );
    }

    if (ha('buco') || ha('muro')) {
      idee.add(
        const Idea(
          titolo: 'Chiudere un buco nel muro',
          descrizione: 'Classico lavoro di sistemazione domestica.',
          tempo: '20-40 minuti',
          difficolta: 'Facile-media',
          serve: 'Stucco, spatola, carta abrasiva',
          comeFare:
              'Pulisci la zona, applica lo stucco, lascia asciugare e poi leviga.',
          googleQuery: 'come chiudere un buco nel muro',
          youtubeQuery: 'come chiudere un buco nel muro video',
        ),
      );
    }

    if (ha('legno')) {
      idee.add(
        const Idea(
          titolo: 'Piccolo progetto in legno',
          descrizione: 'Il legno ti permette mensole, supporti o rinforzi.',
          tempo: '30-60 minuti',
          difficolta: 'Media',
          serve: 'Legno, viti, metro, avvitatore',
          comeFare:
              'Prendi bene le misure, segna i tagli e monta con ordine.',
          googleQuery: 'progetti semplici in legno fai da te',
          youtubeQuery: 'progetti semplici in legno fai da te video',
        ),
      );
    }

    if (ha('cartongesso')) {
      idee.add(
        const Idea(
          titolo: 'Piccolo lavoro in cartongesso',
          descrizione: 'Utile per chiudere, rivestire o rifinire.',
          tempo: '1-2 ore',
          difficolta: 'Media',
          serve: 'Lastra, viti, struttura, cutter',
          comeFare:
              'Misura, taglia il cartongesso, fissalo e rifinisci le giunzioni.',
          googleQuery: 'lavori in cartongesso fai da te',
          youtubeQuery: 'lavori in cartongesso fai da te video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Lavoro fai-da-te base',
          descrizione: 'Ti oriento verso un lavoro semplice e ordinato.',
          tempo: '30 minuti',
          difficolta: 'Media',
          serve: 'Quello che hai scritto: $testoOriginale',
          comeFare:
              'Parti sempre da misure e attrezzi, poi fai una prova semplice prima del lavoro definitivo.',
          googleQuery: '$testoOriginale fai da te',
          youtubeQuery: '$testoOriginale fai da te video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  if (categoria == 'Lavoro') {
    if (ha('guadagnare') || ha('soldi')) {
      idee.add(
        const Idea(
          titolo: 'Servizio a domicilio',
          descrizione:
              'Partire da un servizio concreto spesso è la via più rapida.',
          tempo: 'Da subito',
          difficolta: 'Media',
          serve: 'Una competenza reale e contatti',
          comeFare:
              'Scegli una cosa che sai fare, metti un prezzo semplice e proponila a persone vere.',
          googleQuery: 'idee per guadagnare da casa o a domicilio',
          youtubeQuery: 'idee per guadagnare da casa video',
        ),
      );
    }

    if (ha('casa') || ha('online')) {
      idee.add(
        const Idea(
          titolo: 'Piccola attività da casa',
          descrizione: 'Meglio semplice, utile e subito proponibile.',
          tempo: '1-2 ore al giorno',
          difficolta: 'Media',
          serve: 'Telefono, organizzazione, offerta chiara',
          comeFare:
              'Definisci cosa offri, a chi serve e come ti contattano, poi pubblicalo dove hai già contatti reali.',
          googleQuery: 'idee lavoro da casa online',
          youtubeQuery: 'idee lavoro da casa online video',
        ),
      );
    }

    if (ha('clienti')) {
      idee.add(
        const Idea(
          titolo: 'Ricerca clienti',
          descrizione: 'Qui conta la proposta, non le parole difficili.',
          tempo: '1 ora',
          difficolta: 'Media',
          serve: 'Lista contatti e messaggio chiaro',
          comeFare:
              'Scrivi cosa offri in una frase e contatta 10 persone o attività in modo diretto.',
          googleQuery: 'come trovare clienti',
          youtubeQuery: 'come trovare clienti video',
        ),
      );
    }

    if (ha('budget') || ha('poco')) {
      idee.add(
        const Idea(
          titolo: 'Idea con poco budget',
          descrizione: 'Con pochi soldi devi partire leggero.',
          tempo: 'Da subito',
          difficolta: 'Facile-media',
          serve: 'Quello che sai già fare',
          comeFare:
              'Offri un servizio, non comprare subito cose inutili, testa l’idea e reinvesti solo dopo.',
          googleQuery: 'idee business poco budget',
          youtubeQuery: 'idee business poco budget video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Idea lavoro concreta',
          descrizione: 'Meglio una proposta semplice che dieci idee confuse.',
          tempo: '1 ora per partire',
          difficolta: 'Media',
          serve: 'Competenza, chiarezza, contatti',
          comeFare:
              'Scrivi cosa sai fare, a chi serve e quanto costa. Poi proponilo subito.',
          googleQuery: '$testoOriginale lavoro business',
          youtubeQuery: '$testoOriginale lavoro video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  if (categoria == 'Hobby') {
    if (ha('creativo')) {
      idee.add(
        const Idea(
          titolo: 'Hobby creativo',
          descrizione: 'Adatto se vuoi esprimerti e creare qualcosa.',
          tempo: '30-60 minuti',
          difficolta: 'Facile',
          serve: 'Carta, colori o materiale base',
          comeFare:
              'Puoi iniziare con disegno, decorazioni, scrittura o personalizzazione oggetti.',
          googleQuery: 'hobby creativi idee',
          youtubeQuery: 'hobby creativi idee video',
        ),
      );
    }

    if (ha('rilassante')) {
      idee.add(
        const Idea(
          titolo: 'Hobby rilassante',
          descrizione: 'Perfetto se vuoi staccare la testa.',
          tempo: '20-40 minuti',
          difficolta: 'Facile',
          serve: 'Ambiente tranquillo',
          comeFare:
              'Prova lettura, musica, puzzle, scrittura libera o colorazione.',
          googleQuery: 'hobby rilassanti idee',
          youtubeQuery: 'hobby rilassanti idee video',
        ),
      );
    }

    if (ha('manuale')) {
      idee.add(
        const Idea(
          titolo: 'Hobby manuale',
          descrizione: 'Adatto se ti piace usare le mani e vedere risultati.',
          tempo: '30-90 minuti',
          difficolta: 'Media',
          serve: 'Materiale semplice',
          comeFare:
              'Puoi iniziare con piccoli lavori decorativi o oggetti fatti a mano.',
          googleQuery: 'hobby manuali idee',
          youtubeQuery: 'hobby manuali idee video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Hobby adatto a te',
          descrizione: 'Ti propongo una direzione semplice ma utile.',
          tempo: '30 minuti',
          difficolta: 'Facile',
          serve: 'Tempo tranquillo',
          comeFare:
              'Scegli tra qualcosa di creativo, rilassante o manuale in base a come ti senti oggi.',
          googleQuery: '$testoOriginale hobby idee',
          youtubeQuery: '$testoOriginale hobby video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  if (categoria == 'Pulizie') {
    if (ha('bagno')) {
      idee.add(
        const Idea(
          titolo: 'Pulizia bagno veloce',
          descrizione: 'Conviene partire dalle cose più visibili.',
          tempo: '15 minuti',
          difficolta: 'Facile',
          serve: 'Panno, detergente, spugna',
          comeFare:
              'Pulisci lavandino e sanitari, passa lo specchio e fai una rifinitura finale.',
          googleQuery: 'come pulire il bagno velocemente',
          youtubeQuery: 'come pulire il bagno velocemente video',
        ),
      );
    }

    if (ha('cucina')) {
      idee.add(
        const Idea(
          titolo: 'Pulizia cucina',
          descrizione: 'Parti da piano lavoro, fornelli e riordino.',
          tempo: '15-20 minuti',
          difficolta: 'Facile',
          serve: 'Panno, sgrassatore, sacchetto rifiuti',
          comeFare:
              'Libera il piano, pulisci superfici e fornelli, butta il superfluo e rimetti a posto.',
          googleQuery: 'come pulire la cucina velocemente',
          youtubeQuery: 'come pulire la cucina velocemente video',
        ),
      );
    }

    if (ha('riordinare') || ha('disordine')) {
      idee.add(
        const Idea(
          titolo: 'Riordino rapido',
          descrizione: 'Prima ordina, poi pulisci.',
          tempo: '10-15 minuti',
          difficolta: 'Facile',
          serve: 'Cestino o scatola',
          comeFare:
              'Raccogli le cose fuori posto, rimettile in ordine e poi passa alle superfici.',
          googleQuery: 'come riordinare casa velocemente',
          youtubeQuery: 'come riordinare casa velocemente video',
        ),
      );
    }

    if (ha('15 minuti') || ha('10 minuti')) {
      idee.add(
        const Idea(
          titolo: 'Pulizia a tempo',
          descrizione: 'Hai poco tempo, quindi serve una mini routine.',
          tempo: '10-15 minuti',
          difficolta: 'Facile',
          serve: 'Timer e panno',
          comeFare:
              'Metti un timer, scegli una zona e fai solo le cose più visibili e utili.',
          googleQuery: 'routine pulizie 15 minuti',
          youtubeQuery: 'routine pulizie 15 minuti video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Routine pulizie base',
          descrizione: 'Quando non sai da dove partire, vai in ordine.',
          tempo: '15-20 minuti',
          difficolta: 'Facile',
          serve: 'Panno e detergente base',
          comeFare:
              'Prima riordina, poi pulisci dall’alto verso il basso e chiudi con un tocco finale.',
          googleQuery: '$testoOriginale pulizie casa',
          youtubeQuery: '$testoOriginale pulizie video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  if (categoria == 'Tempo libero') {
    if (ha('solo')) {
      idee.add(
        const Idea(
          titolo: 'Tempo libero da solo',
          descrizione: 'Meglio qualcosa che ti faccia stare bene davvero.',
          tempo: '30-90 minuti',
          difficolta: 'Facile',
          serve: 'Solo un po’ di voglia',
          comeFare:
              'Fai una passeggiata, guarda un film, ascolta musica o dedicati a qualcosa che rimandi.',
          googleQuery: 'idee tempo libero da solo',
          youtubeQuery: 'idee tempo libero da solo video',
        ),
      );
    }

    if (ha('amici')) {
      idee.add(
        const Idea(
          titolo: 'Idea con amici',
          descrizione: 'Con amici funzionano bene le cose semplici.',
          tempo: '1-3 ore',
          difficolta: 'Facile',
          serve: 'Accordo semplice',
          comeFare:
              'Organizza aperitivo, pizza, carte, film o passeggiata.',
          googleQuery: 'idee da fare con amici',
          youtubeQuery: 'idee da fare con amici video',
        ),
      );
    }

    if (ha('poco') || ha('spendere poco') || ha('gratis')) {
      idee.add(
        const Idea(
          titolo: 'Idea economica',
          descrizione: 'Non serve spendere tanto per passare bene il tempo.',
          tempo: '30-120 minuti',
          difficolta: 'Facile',
          serve: 'Zero o poco budget',
          comeFare:
              'Passeggiata, posto nuovo, serata in casa, musica o film fatto bene.',
          googleQuery: 'idee tempo libero spendere poco',
          youtubeQuery: 'idee tempo libero spendere poco video',
        ),
      );
    }

    if (ha('serata tranquilla')) {
      idee.add(
        const Idea(
          titolo: 'Serata tranquilla',
          descrizione: 'Se vuoi calma, evita cose dispersive.',
          tempo: '1-2 ore',
          difficolta: 'Facile',
          serve: 'Relax',
          comeFare:
              'Cena semplice, film, musica o tempo senza troppe distrazioni.',
          googleQuery: 'idee serata tranquilla',
          youtubeQuery: 'idee serata tranquilla video',
        ),
      );
    }

    if (idee.isEmpty) {
      idee.add(
        Idea(
          titolo: 'Qualcosa di diverso',
          descrizione: 'A volte basta cambiare ritmo.',
          tempo: '30-60 minuti',
          difficolta: 'Facile',
          serve: 'Un po’ di iniziativa',
          comeFare:
              'Esci, cambia ambiente, fai due passi o scegli un’attività leggera ma diversa.',
          googleQuery: '$testoOriginale tempo libero idee',
          youtubeQuery: '$testoOriginale tempo libero video',
        ),
      );
    }

    return rimuoviDuplicati(idee);
  }

  return idee;
}

List<Idea> rimuoviDuplicati(List<Idea> idee) {
  final Map<String, Idea> mappa = {};
  for (final idea in idee) {
    mappa[idea.titolo] = idea;
  }
  return mappa.values.toList();
}