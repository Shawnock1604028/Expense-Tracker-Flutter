import 'package:flutter/material.dart';
import '../data/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Currency'),
            subtitle: ValueListenableBuilder<Currency>(
              valueListenable: AppState.instance.selectedCurrency,
              builder: (context, currency, _) {
                return Text('${currency.name} (${currency.symbol})');
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: AppState.availableCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = AppState.availableCurrencies[index];
                    return ValueListenableBuilder<Currency>(
                      valueListenable: AppState.instance.selectedCurrency,
                      builder: (context, selected, _) {
                        return ListTile(
                          title: Text(currency.name),
                          subtitle: Text(currency.code),
                          trailing: Text(
                            currency.symbol,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          selected: selected.code == currency.code,
                          onTap: () {
                            AppState.instance.setSelectedCurrency(currency);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
