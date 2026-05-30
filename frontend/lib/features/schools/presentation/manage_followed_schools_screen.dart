import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../schools/data/school_dtos.dart';  
import '../../schools/data/school_repository.dart';  
  
class ManageFollowedSchoolsScreen extends ConsumerStatefulWidget {  
  const ManageFollowedSchoolsScreen({super.key});  
  
  @override  
  ConsumerState<ManageFollowedSchoolsScreen> createState() =>  
      _ManageFollowedSchoolsScreenState();  
}  
  
class _ManageFollowedSchoolsScreenState  
    extends ConsumerState<ManageFollowedSchoolsScreen> {  
  bool _loading = false;  
  String? _error;  
  List<School> _schools = const [];  
  
  @override  
  void initState() {  
    super.initState();  
    _load();  
  }  
  
  Future<void> _load() async {  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      final page = await ref  
          .read(schoolRepositoryProvider)  
          .myFollowedSchools(limit: 100);  
      setState(() {  
        _schools = page.items;  
      });  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _unfollow(School school) async {  
    final confirmed = await showDialog<bool>(  
      context: context,  
      builder: (ctx) => AlertDialog(  
        title: const Text('Unfollow school?'),  
        content: Text('Stop following ${school.schoolName}?'),  
        actions: [  
          TextButton(  
            onPressed: () => Navigator.of(ctx).pop(false),  
            child: const Text('Cancel'),  
          ),  
          FilledButton(  
            onPressed: () => Navigator.of(ctx).pop(true),  
            child: const Text('Unfollow'),  
          ),  
        ],  
      ),  
    );  
    if (confirmed != true) return;  
  
    try {  
      await ref.read(schoolRepositoryProvider).unfollow(school.id);  
      if (!mounted) return;  
      await _load();  
      ScaffoldMessenger.of(context).showSnackBar(  
        SnackBar(content: Text('Unfollowed ${school.schoolName}')),  
      );  
    } catch (e) {  
      if (!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(  
        SnackBar(content: Text(e.toString())),  
      );  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    return ResponsiveShell(  
      title: 'Followed schools',  
      leading: IconButton(  
        icon: const Icon(Icons.arrow_back),  
        onPressed: () => context.go('/profile'),  
      ),  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.stretch,  
        children: [  
          Text(  
            'Schools you follow',  
            style: theme.textTheme.headlineSmall,  
          ),  
          const SizedBox(height: 8),  
          const Text(  
            'You will receive announcements from these schools.',  
          ),  
          const SizedBox(height: 16),  
          if (_loading)  
            const Center(child: CircularProgressIndicator())  
          else if (_error != null)  
            Card(  
              color: theme.colorScheme.errorContainer,  
              child: Padding(  
                padding: const EdgeInsets.all(12),  
                child: Text(_error!),  
              ),  
            )  
          else if (_schools.isEmpty)  
            const Card(  
              child: Padding(  
                padding: EdgeInsets.all(16),  
                child: Text('You are not following any schools yet.'),  
              ),  
            )  
          else  
            Column(  
              children: [  
                for (final school in _schools)  
                  Card(  
                    child: ListTile(  
                      title: Text(school.schoolName),  
                      subtitle: Text(school.subCity != null ? '${school.subCity} - ${school.woreda ?? 'N/A'}' : 'No location info'),  
                      trailing: IconButton(  
                        tooltip: 'Unfollow',  
                        onPressed: () => _unfollow(school),  
                        icon: const Icon(Icons.person_remove),  
                      ),  
                    ),  
                  ),  
              ],  
            ),  
        ],  
      ),  
    );  
  }  
}