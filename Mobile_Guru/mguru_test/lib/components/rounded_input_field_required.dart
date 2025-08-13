import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/components/text_field_container.dart';
import 'package:mobile_presensi_kdtg/constants.dart';

class RoundedInputFieldRequired extends StatelessWidget {
  final String hintText, pesan;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType type;
  final TextEditingController IdCon;

  const RoundedInputFieldRequired({
    Key? key,
    required this.hintText,
    this.icon = Icons.person,
    required this.onChanged,
    required this.pesan,
    required this.type,
    required this.IdCon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
          controller: IdCon,
          onChanged: onChanged,
          cursorColor: kPrimaryColor,
          keyboardType: type,
          decoration: InputDecoration(
            icon: Icon(
              icon,
              color: kPrimaryColor,
            ),
            hintText: hintText,
            border: InputBorder.none,
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return pesan;
            }
            return null;
          }),
    );
  }
}
