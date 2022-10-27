import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
        create: (context) => TodoModel(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Launch Checklist',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: Home());
  }
}

class Home extends StatelessWidget {
  final TextEditingController _textFieldController = TextEditingController();

  Home({super.key});

  Future<void> _displayTextInputDialog(BuildContext context, int index) async {
    _textFieldController.clear();
    if (index >= 0) {
      TodoModel todoModel = context.read<TodoModel>();
      _textFieldController.text = todoModel._items[index].name;
    }

    return showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            title: const Text('Checklist Step'),
            content: TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "New step text"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  _textFieldController.clear();
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text('SAVE'),
                onPressed: () {
                  String stepTxt = _textFieldController.text;
                  if (stepTxt.isNotEmpty) {
                    TodoModel todoModel = context.read<TodoModel>();
                    if (index >= 0) {
                      todoModel.update(index, stepTxt);
                    } else {
                      todoModel.add(stepTxt);
                    }
                  }
                  _textFieldController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    bool isIOS = Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.rocket),
        title: const Text("Launch Checklist"),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                TodoModel todoModel = context.read<TodoModel>();
                todoModel.resetAll();
              }),
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _displayTextInputDialog(context, -1);
              }),
        ],
      ),
      body: Consumer<TodoModel>(builder: (context, todoModel, child) {
        return ReorderableListView(
            children: <Widget>[
              for (int index = 0; index < todoModel._items.length; index += 1)
                Dismissible(
                    key: ObjectKey(todoModel._items[index]),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _displayTextInputDialog(context, index);
                        return false;
                      } else {
                        return true;
                      }
                    },
                    onDismissed: (direction) {
                      todoModel.remove(index);
                    },
                    background: Container(
                      color: Colors.blueAccent,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Icon(Icons.edit),
                        ),
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete),
                        ),
                      ),
                    ),
                    child: Card(
                        key: Key('$index'),
                        child: ListTile(
                          key: Key('$index'),
                          title: Text(todoModel._items[index].name),
                          tileColor: todoModel._items[index].isSelected
                              ? Colors.green
                              : Colors.white,
                          trailing: isIOS
                              ? CupertinoSwitch(
                                  value: todoModel._items[index].isSelected,
                                  onChanged: (bool value) =>
                                      todoModel.setComplete(index, value))
                              : Switch(
                                  value: todoModel._items[index].isSelected,
                                  onChanged: (bool value) =>
                                      todoModel.setComplete(index, value)),
                        ))),
            ],
            onReorder: (int oldIndex, int newIndex) {
              todoModel.move(oldIndex, newIndex);
            });
      }),
    );
  }
}

class TodoItem {
  String name;
  final Key key;
  bool isSelected = false;

  TodoItem({required this.key, required this.name});
}

class TodoModel extends ChangeNotifier {
  final List<TodoItem> _items = [];

  TodoModel() {
    loadFromPrefs();
  }

  void add(String nameStr) {
    TodoItem it =
        TodoItem(key: ValueKey(_items.length.toString()), name: nameStr);
    _items.add(it);
    saveToPrefs();
    notifyListeners();
  }

  void remove(int idx) {
    _items.removeAt(idx);
    saveToPrefs();
    notifyListeners();
  }

  void update(int idx, String nameStr) {
    _items[idx].name = nameStr;
    saveToPrefs();
    notifyListeners();
  }

  void move(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final TodoItem item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    saveToPrefs();
    notifyListeners();
  }

  void setComplete(int index, bool value) {
    _items[index].isSelected = value;
    notifyListeners();
  }

  void resetAll() {
    for (var element in _items) {
      element.isSelected = false;
    }
    notifyListeners();
  }

  Future<void> loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? checkListStrings = prefs.getStringList("rocket_checklist");
    if (checkListStrings == null || checkListStrings.isEmpty) {
      checkListStrings = [
        "Pad is safe",
        "Igniter is safe",
        "Rail is lowered pointing away from flight line",
        "Airframe is loaded",
        "Rail is raised",
        "Electronics armed and verified",
        "Igniter inserted and connected",
        "Continuity verified",
        "Pad is armed",
      ];

      saveToPrefs();
    }

    for (var nameStr in checkListStrings) {
      add(nameStr);
    }
  }

  Future<void> saveToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> checkListStrs = [];
    for (var item in _items) {
      checkListStrs.add(item.name);
    }
    prefs.setStringList("rocket_checklist", checkListStrs);
  }
}
