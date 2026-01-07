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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('My To-Do List'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.logout),
            color: Colors.redAccent,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (totalCount > 0)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.indigo.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Completed $completedCount of $totalCount tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                                color: Colors.indigo.shade100,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Todos yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.indigo.shade200,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tap the + button to add one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(8),
                          itemCount: todos.length,
                          itemBuilder: (context, index) {
                            final todo = todos[index];
                            return Card(
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: todo['is_completed'],
                                  onChanged: (value) {
                                    _toggle(todo['id'], todo['is_completed']);
                                  },
                                ),
                                title: Text(
                                  todo['title'],
                                  style: TextStyle(
                                    decoration: todo['is_completed']
                                        ? TextDecoration.lineThrough
                                        : null,

                                    color: todo['is_completed']
                                        ? Colors.grey
                                        : Colors.indigo,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () => _deleteTodo(todo['id']),
                                  icon: Icon(
                                    Icons.delete,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}
