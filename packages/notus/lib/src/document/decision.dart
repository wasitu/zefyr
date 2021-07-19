// import 'package:notus/notus.dart';

import 'block.dart';
import 'attributes.dart';

class DecisionNode extends BlockNode {
  @override
  DecisionNode clone() {
    final node = DecisionNode();
    node.applyStyle(style);
    return node;
  }

  @override
  String toString() {
    final decision = style.value(NotusAttribute.decision);
    final buffer = StringBuffer('§ {$decision}\n');
    for (var child in children) {
      final tree = child.isLast ? '└' : '├';
      buffer.write('  $tree $child');
      if (!child.isLast) buffer.writeln();
    }
    return buffer.toString();
  }
}
