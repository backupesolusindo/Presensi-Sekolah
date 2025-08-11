import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:date_format/date_format.dart';

class FlatDateField extends StatefulWidget {
  final String hintText;
  final TextEditingController IdCon;
  final double width;
  final Color color, textColor;
  const FlatDateField({
    Key? key,
    required this.hintText,
    required this.IdCon,
    required this.width,
    this.color = kPrimaryColor,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  _FlatDateField createState() => _FlatDateField();
}

class _FlatDateField extends State<FlatDateField> {
  DateTime? dateTime;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      width: widget.width > 0 ? widget.width : size.width * 0.8,
      child: TextFormField(
          controller: widget.IdCon,
          cursorColor: kPrimaryColor,
          showCursor: true,
          readOnly: true,
          style: const TextStyle(
            fontSize: 14,
          ),
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
            labelText: widget.hintText,
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: kPrimaryColor),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: softblue),
            ),
            suffixIcon: const Icon(
              Icons.date_range,
              color: kPrimaryColor,
            ),
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return "${widget.hintText} Harus Diisi";
            }
            return null;
          }),
    );
  }
}
