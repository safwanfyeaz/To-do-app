import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> todos = [];

  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _fetchTodos();
    _subscribeToTodos();
  }

  @override
  void dispose() {
    supabase.removeAllChannels();
    super.dispose();
  }

  Future<void> _fetchTodos() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await supabase
          .from('todos')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      setState(() {
        todos = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching todos: $e')));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _subscribeToTodos() {
    supabase
        .channel('todos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'todos',
          callback: (payload) => _fetchTodos(),
        )
        .subscribe();
  }

  Future<void> _addTodo(String title) async {
    try {
      await supabase.from('todos').insert({
        'title': title,
        'user_id': supabase.auth.currentUser!.id,
        'is_completed': false,
      });
      _fetchTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding todo: $e')));
      }
    }
  }

  Future<void> _toggle(int id, bool currentStatus) async {
    try {
      await supabase
          .from('todos')
          .update({'is_completed': !currentStatus})
          .eq('id', id);
      _fetchTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating todo: $e')));
      }
    }
  }

  Future<void> _deleteTodo(int id) async {
    try {
      await supabase.from('todos').delete().eq('id', id);
      _fetchTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting todo: $e')));
      }
    }
  }

  void _showAddTodoDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add To-Do"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter to-do title"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                _addTodo(title);
              }
              Navigator.of(context).pop();
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = todos
        .where((todo) => todo['is_completed'] == true)
        .length;
    final totalCount = todos.length;

    return Scaffold(
      // A soft grey background makes the pure white cards "pop"
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My To-Do List',
          style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            color: Colors.redAccent,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    if (totalCount > 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 0,
                          color: Colors.indigo[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Completed $completedCount of $totalCount tasks',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: todos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 80,
                                    color: Colors.indigo[100],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Todos yet.',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.indigo[200],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: todos.length,
                              itemBuilder: (context, index) {
                                final todo = todos[index];
                                return Card(
                                  color: Colors
                                      .white, // High contrast against the grey background
                                  elevation: 3,
                                  shadowColor: Colors.black26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 4,
                                    ),
                                    leading: Checkbox(
                                      activeColor: Colors.indigo,
                                      value: todo['is_completed'],
                                      onChanged: (value) => _toggle(
                                        todo['id'],
                                        todo['is_completed'],
                                      ),
                                    ),
                                    title: Text(
                                      todo['title'],
                                      style: TextStyle(
                                        decoration: todo['is_completed']
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: todo['is_completed']
                                            ? Colors.grey
                                            : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      onPressed: () => _deleteTodo(todo['id']),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
    );
  }
}
