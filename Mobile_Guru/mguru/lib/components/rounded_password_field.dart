import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/components/text_field_container.dart';
import '../constants.dart';

class RoundedPasswordField extends StatefulWidget {
  final String hintText;
  final TextEditingController IdCon;

  const RoundedPasswordField(
      {Key? key, required this.hintText, required this.IdCon})
      : super(key: key);

  @override
  _RoundedPasswordField createState() => _RoundedPasswordField();
}

class _RoundedPasswordField extends State<RoundedPasswordField> {
  bool passVisible = true;
  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
          controller: widget.IdCon,
          obscureText: passVisible,
          cursorColor: kPrimaryColor,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            hintText: widget.hintText,
            icon: const Icon(
              Icons.lock,
              color: kPrimaryColor,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                passVisible ? Icons.visibility_off : Icons.visibility,
                color: kPrimaryColor,
              ),
              onPressed: () {
                setState(() {
                  passVisible = !passVisible;
                });
              },
            ),
            border: InputBorder.none,
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return "Password Harus Diisi";
            }
            return null;
          }),
    );
  }
}
