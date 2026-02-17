import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mox_beta/components/my_textfield.dart';

class UserInformation extends StatefulWidget {
  const UserInformation({super.key});

  @override
  _UserInformationState createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  final _searchController = TextEditingController();
  String _term = '';
  final _usersCollection = FirebaseFirestore.instance.collection('Users');

  Stream<QuerySnapshot> get _usersStream =>
      _usersCollection.limit(100).snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MyTextField(
        hintText: 'Search nickname',
        obscureText: false,
        controller: _searchController,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _term.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _term = '');
                },
              ),
        onChanged: (s) => setState(() => _term = s.trim().toLowerCase()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchInput(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersStream,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snap.data!.docs;
              final results = allDocs.where((d) {
                final m = d.data()! as Map<String, dynamic>;
                final nick = (m['nickname'] ?? '').toString().toLowerCase();
                return _term.isEmpty || nick.contains(_term);
              }).toList();

              if (results.isEmpty) {
                return const Center(child: Text('No results'));
              }

              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final m = results[i].data()! as Map<String, dynamic>;
                  final nick = m['nickname'] ?? '—';
                  final email = m['email'] ?? '';
                  return ListTile(
                    title: Text(nick.toString()),
                    subtitle: Text(email.toString()),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
