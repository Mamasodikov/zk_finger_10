import 'package:flutter/material.dart';
import 'package:zkfinger10/zk_finger.dart';

class BidirectionalTestPage extends StatefulWidget {
  const BidirectionalTestPage({Key? key}) : super(key: key);

  @override
  State<BidirectionalTestPage> createState() => _BidirectionalTestPageState();
}

class _BidirectionalTestPageState extends State<BidirectionalTestPage> {
  String _status = 'Ready to test bidirectional functionality';
  Map<String, String>? _allUsers;
  int? _userCount;
  String? _userFeature;
  bool? _userExists;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bidirectional Data Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test buttons
            ElevatedButton(
              onPressed: _testGetUserCount,
              child: const Text('Get User Count'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testGetAllUsers,
              child: const Text('Get All Users'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () => _testGetUserFeature('test_user'),
              child: const Text('Get User Feature (test_user)'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () => _testCheckUserExists('test_user'),
              child: const Text('Check User Exists (test_user)'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () => _testUpdateUserFeature('test_user', 'sample_feature_data'),
              child: const Text('Update User Feature (test_user)'),
            ),
            const SizedBox(height: 20),
            
            // Results display
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userCount != null) ...[
                      Text('User Count: $_userCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                    ],
                    
                    if (_userExists != null) ...[
                      Text('User Exists: $_userExists', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                    ],
                    
                    if (_userFeature != null) ...[
                      const Text('User Feature:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_userFeature!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                    ],
                    
                    if (_allUsers != null) ...[
                      const Text('All Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._allUsers!.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                          child: Text('${entry.key}: ${entry.value.substring(0, 20)}...'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGetUserCount() async {
    try {
      setState(() => _status = 'Getting user count...');
      final count = await ZkFinger.getUserCount();
      setState(() {
        _userCount = count;
        _status = 'User count retrieved: $count';
      });
    } catch (e) {
      setState(() => _status = 'Error getting user count: $e');
    }
  }

  Future<void> _testGetAllUsers() async {
    try {
      setState(() => _status = 'Getting all users...');
      final users = await ZkFinger.getAllUsers();
      setState(() {
        _allUsers = users;
        _status = 'All users retrieved: ${users?.length ?? 0} users';
      });
    } catch (e) {
      setState(() => _status = 'Error getting all users: $e');
    }
  }

  Future<void> _testGetUserFeature(String userId) async {
    try {
      setState(() => _status = 'Getting user feature for $userId...');
      final feature = await ZkFinger.getUserFeature(userId: userId);
      setState(() {
        _userFeature = feature;
        _status = feature != null 
          ? 'User feature retrieved for $userId'
          : 'No feature found for $userId';
      });
    } catch (e) {
      setState(() => _status = 'Error getting user feature: $e');
    }
  }

  Future<void> _testCheckUserExists(String userId) async {
    try {
      setState(() => _status = 'Checking if user $userId exists...');
      final exists = await ZkFinger.checkUserExists(userId: userId);
      setState(() {
        _userExists = exists;
        _status = 'User $userId ${exists == true ? 'exists' : 'does not exist'}';
      });
    } catch (e) {
      setState(() => _status = 'Error checking user existence: $e');
    }
  }

  Future<void> _testUpdateUserFeature(String userId, String feature) async {
    try {
      setState(() => _status = 'Updating user feature for $userId...');
      final success = await ZkFinger.updateUserFeature(userId: userId, feature: feature);
      setState(() {
        _status = success == true 
          ? 'User feature updated successfully for $userId'
          : 'Failed to update user feature for $userId';
      });
    } catch (e) {
      setState(() => _status = 'Error updating user feature: $e');
    }
  }
}
