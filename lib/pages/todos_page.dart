import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:todo_app/models/todo_model.dart';
import 'package:todo_app/providers/active_todo_count.dart';
import 'package:todo_app/providers/providers.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              children: const [
                TodoHeader(),
                CreateTodo(),
                SearchAndFilterTodo(),
                ShowTodos(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodoHeader extends StatelessWidget {
  const TodoHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Todo",
          style: TextStyle(fontSize: 40.0),
        ),
        Text(
          "${context.watch<ActiveTodoCount>().state.activeTodoCount} items left",
          style: const TextStyle(fontSize: 20.0, color: Colors.redAccent),
        ),
      ],
    );
  }
}

class CreateTodo extends StatefulWidget {
  const CreateTodo({Key? key}) : super(key: key);

  @override
  State<CreateTodo> createState() => _CreateTodoState();
}

class _CreateTodoState extends State<CreateTodo> {
  //
  final newTodoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: newTodoController,
      decoration: const InputDecoration(labelText: "What to do ?"),
      onSubmitted: (String? todoDescription) {
        if (todoDescription != null && todoDescription.trim().isNotEmpty) {
          context.read<TodoList>().addTodo(todoDescription);
          newTodoController.clear();
        }
      },
    );
  }

  @override
  void dispose() {
    newTodoController.dispose();
    super.dispose();
  }
}

class SearchAndFilterTodo extends StatelessWidget {
  const SearchAndFilterTodo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      //
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: "Search Todos",
            border: InputBorder.none,
            filled: true,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (String? newSearchTerm) {
            if (newSearchTerm != null) {
              context.read<TodoSearch>().setSearchTerm(newSearchTerm);
            }
          },
        ),
        const SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            filterButton(context, Filter.all),
            filterButton(context, Filter.completed),
            filterButton(context, Filter.active),
          ],
        )
      ],
    );
  }
}

Widget filterButton(BuildContext context, Filter filter) {
  return TextButton(
      onPressed: () {
        context.read<TodoFilter>().changeFilter(filter);
      },
      child: Text(
        filter == Filter.all
            ? "All"
            : filter == Filter.active
                ? "Active"
                : "Completed",
        style: TextStyle(fontSize: 18.0, color: textColor(context, filter)),
      ));
}

Color textColor(BuildContext context, Filter filter) {
  final currentFilter = context.watch<TodoFilter>().state.filter;
  return currentFilter == filter ? Colors.blue : Colors.grey;
}

class ShowTodos extends StatelessWidget {
  const ShowTodos({Key? key}) : super(key: key);

  Widget showBackground(int direction) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      color: Colors.red,
      alignment: direction == 0 ? Alignment.centerLeft : Alignment.centerRight,
      child: const Icon(
        Icons.delete,
        size: 30.0,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<FilterdTodos>().state.filterdTodos;

    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      itemCount: todos.length,
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(color: Colors.grey);
      },
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          key: ValueKey(todos[index].id),

          //
          onDismissed: (_) {
            context.read<TodoList>().removeTodo(todos[index].id);
          },

          //
          confirmDismiss: (_) {
            return showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Are you sure ?"),
                    content: const Text("Do you really want to delete?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("No")),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("YES")),
                    ],
                  );
                });
          },
          background: showBackground(0),
          secondaryBackground: showBackground(1),
          child: TodoItem(todo: todos[index]),
        );
      },
    );
  }
}

class TodoItem extends StatefulWidget {
  final Todo todo;
  const TodoItem({
    Key? key,
    required this.todo,
  }) : super(key: key);

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      //
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              bool _error = false;
              textController.text = widget.todo.description;
              return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: Text("Edit Todo"),
                  content: TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                        errorText: _error ? "Value cannot be empty" : null),
                  ),

                  //
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _error = textController.text.isEmpty ? true : false;
                          });
                          if (!_error) {
                            context.read<TodoList>().editTodo(
                                widget.todo.id, widget.todo.description);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Edit")),
                  ],
                );
              });
            });
      },

      //
      leading: Checkbox(
        value: widget.todo.isCompleted,
        onChanged: (_) {
          context.read<TodoList>().toggleTodo(widget.todo.id);
        },
      ),
      title:
          Text(widget.todo.description, style: const TextStyle(fontSize: 20.0)),
    );
  }
}
