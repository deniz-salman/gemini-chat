import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton(
      {required this.icon,
      required this.text,
      required this.onPressed,
      Key? key})
      : super(key: key);

  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          10.horizontalSpace,
          Icon(icon),
          10.horizontalSpace,
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.deepPurple,
                ),
          ),
        ],
      ),
    );
  }
}
