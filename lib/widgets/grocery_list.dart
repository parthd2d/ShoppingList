import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({
    super.key,
  });

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-6ab88-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);

      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.title == item.value['category'])
            .value;

        loadedItems.add(
          GroceryItem(
            category: category,
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong. Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });

    return;
  }

  void _removeItem(GroceryItem item) async {
    final idx = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 3),
        content: Text('Item deleted.'),
      ),
    );

    final url = Uri.https(
      'flutter-prep-6ab88-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(idx, item);
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Couldn\'t delete item.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, idx) {
          return Dismissible(
            background: Container(
              color: Theme.of(context).colorScheme.error.withOpacity(1),
            ),
            onDismissed: (direction) {
              _removeItem(_groceryItems[idx]);
            },
            key: ValueKey(_groceryItems[idx].id),
            child: ListTile(
              title: Text(_groceryItems[idx].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[idx].category.color,
              ),
              trailing: Text(
                _groceryItems[idx].quantity.toString(),
              ),
            ),
          );
        },
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }
}
