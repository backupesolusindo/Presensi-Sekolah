import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/components/text_field_container.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:date_format/date_format.dart';

class RoundedDateField extends StatefulWidget {
  final String hintText;
  final TextEditingController IdCon;
  const RoundedDateField({
    Key? key,
    required this.hintText,
    required this.IdCon,
  }) : super(key: key);

  @override
  _RoundedDateField createState() => _RoundedDateField();
}

class _RoundedDateField extends State<RoundedDateField> {
  DateTime? dateTime;
  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
          controller: widget.IdCon,
          cursorColor: kPrimaryColor,
          showCursor: true,
          readOnly: true,
          onTap: () {
            showDatePicker(
                    context: context,
                    initialDate: dateTime == null ? DateTime.now() : dateTime!,
                    firstDate: DateTime(2021),
                    lastDate: DateTime(3000))
                .then((date) {
              setState(() {
                dateTime = date!;
                final formattedStr = formatDate(date, [dd, '-', mm, '-', yyyy]);
                widget.IdCon.text = formattedStr.toString();
              });
            });
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            icon: Icon(
              Icons.date_range,
              color: kPrimaryColor,
            ),
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return widget.hintText + " Harus Diisi";
            }
            return null;
          }),
    );
  }
}
