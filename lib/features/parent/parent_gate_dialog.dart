import 'package:flutter/material.dart';

class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({
    super.key,
    required this.expectedPin,
  });

  final String expectedPin;

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verify() {
    if (_pinController.text.trim() == widget.expectedPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Mã PIN chưa đúng (mặc định: 1234)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cổng Phụ Huynh'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nhập mã PIN phụ huynh để vào cài đặt và báo cáo.'),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Mã PIN',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _verify,
          child: const Text('Mở khóa'),
        ),
      ],
    );
  }
}
