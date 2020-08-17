// import 'package:notus/notus.dart';

import 'block.dart';
import 'attributes.dart';

class CheckboxNode extends BlockNode {
  @override
  CheckboxNode clone() {
    final node = CheckboxNode();
    node.applyStyle(style);
    return node;
  }

  @override
  String toString() {
    final checkbox = style.value(NotusAttribute.checkbox);
    final buffer = StringBuffer('§ {$checkbox}\n');
    for (var child in children) {
      final tree = child.isLast ? '└' : '├';
      buffer.write('  $tree $child');
      if (!child.isLast) buffer.writeln();
    }
    return buffer.toString();
  }
}
