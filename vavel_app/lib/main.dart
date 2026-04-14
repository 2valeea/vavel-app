import 'package:flutter/material.dart';

import 'send_screen.dart';

void main() => runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: VavelApp()),
    );

class VavelApp extends StatefulWidget {
  const VavelApp({super.key});

  @override
  State<VavelApp> createState() => _VavelAppState();
}

class _VavelAppState extends State<VavelApp> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A16),
      body: <Widget>[
        const _WalletBody(),
        const _TitleScreen(title: 'MARKET LIVE'),
        const _TitleScreen(title: 'DAPP BROWSER'),
        const _SettingsBody(),
      ][_idx],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF00241F),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'VAVEL'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Browser',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _TitleScreen extends StatelessWidget {
  const _TitleScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF004D40), Color(0xFF001A16)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            const Text(
              'VAVEI INNOVATION TOKEN',
              style: TextStyle(color: Colors.white70, letterSpacing: 2),
            ),
            const Text(
              '450,000.00',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              r'$15,200.50 USD',
              style: TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _WalletActionButton(
                  icon: Icons.download,
                  label: 'Receive',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receive (stub).')),
                    );
                  },
                ),
                _WalletActionButton(
                  icon: Icons.upload,
                  label: 'Send',
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => const SendScreen(),
                      ),
                    );
                  },
                ),
                _WalletActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Swap',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Swap (stub).')),
                    );
                  },
                ),
              ],
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'ASSETS: VAVEI, TON, USDT',
                  style: TextStyle(color: Color(0xFF00E676)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: const Color(0xFF00E676),
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const <Widget>[
        ListTile(
          leading: Icon(Icons.language),
          title: Text('Language'),
          trailing: Text('Russian'),
        ),
        ListTile(
          leading: Icon(Icons.support_agent),
          title: Text('Support Center'),
        ),
        ListTile(
          leading: Icon(Icons.lock),
          title: Text('Security'),
        ),
      ],
    );
  }
}
