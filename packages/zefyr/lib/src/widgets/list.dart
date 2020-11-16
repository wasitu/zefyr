// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:notus/notus.dart';
import 'package:numerus/numerus.dart';

import 'common.dart';
import 'paragraph.dart';
import 'theme.dart';

/// Represents number lists and bullet lists in a Zefyr editor.
class ZefyrList extends StatelessWidget {
  const ZefyrList({Key key, @required this.node}) : super(key: key);

  final BlockNode node;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    var index = 1;
    for (var child in node.children) {
      items.add(_buildItem(child, index));
      LineNode line = child;
      if (line.style.get(NotusAttribute.indent) ==
          line.nextLine.style.get(NotusAttribute.indent)) {
        index++;
      } else {
        index = 1;
      }
    }

    var padding = node.style.blockTheme(context).padding;

    if (node is CheckboxNode && node.next is CheckboxNode) {
      padding = padding.copyWith(bottom: 0);
    }

    if (node is CheckboxNode && node.previous is CheckboxNode) {
      padding = padding.copyWith(top: 0);
    }

    return Padding(
      padding: padding,
      child: Column(children: items),
    );
  }

  Widget _buildItem(Node node, int index) {
    LineNode line = node;
    final style = line.style.get(NotusAttribute.indent);
    return ZefyrListItem(index: index, indent: style?.value ?? 0, node: line);
  }
}

/// An item in a [ZefyrList].
class ZefyrListItem extends StatelessWidget {
  ZefyrListItem({
    Key key,
    this.index,
    this.indent = 0,
    this.node,
  }) : super(key: key);

  final int index;
  final int indent;
  final LineNode node;

  @override
  Widget build(BuildContext context) {
    final BlockNode block = node.parent;
    NotusAttribute style;
    if (node.parent is CheckboxNode) {
      style = block.style.get(NotusAttribute.checkbox);
    } else if (node.parent is BlockNode) {
      style = block.style.get(NotusAttribute.block);
    }
    final theme = ZefyrTheme.of(context);
    final blockTheme = block.style.blockTheme(context);

    TextStyle textStyle;
    Widget content;
    EdgeInsets padding;

    if (node.style.contains(NotusAttribute.heading)) {
      final headingTheme = ZefyrHeading.themeOf(node, context);
      textStyle = headingTheme.textStyle;
      padding = headingTheme.padding;
      content = ZefyrHeading(node: node);
    } else {
      textStyle = theme.defaultLineTheme.textStyle;
      content = ZefyrLine(
        node: node,
        style: textStyle,
        padding: blockTheme.linePadding,
      );
      padding = blockTheme.linePadding;
    }

    Widget bullet;
    if (style == NotusAttribute.checkbox.checked) {
      bullet = SizedBox(
          width: 32 * MediaQuery.of(context).textScaleFactor,
          height: 24 * MediaQuery.of(context).textScaleFactor,
          child: Transform.scale(
              scale: 0.8 * MediaQuery.of(context).textScaleFactor,
              child: Checkbox(
                value: true,
                onChanged: (bool value) {},
              )));
    } else if (style == NotusAttribute.checkbox.unchecked) {
      bullet = SizedBox(
          width: 32 * MediaQuery.of(context).textScaleFactor,
          height: 24 * MediaQuery.of(context).textScaleFactor,
          child: Transform.scale(
              scale: 0.8 * MediaQuery.of(context).textScaleFactor,
              child: Checkbox(value: false, onChanged: (bool value) {})));
    } else {
      final bulletText = style.bulletText(index, indent);
      bullet = SizedOverflowBox(
          size: Size(16 + 16 * MediaQuery.of(context).textScaleFactor, 1),
          alignment: (style == NotusAttribute.block.bulletList)
              ? Alignment.topCenter
              : Alignment.topRight,
          child: Row(children: [
            Text(
              bulletText,
              style:
                  textStyle.apply(fontFeatures: [FontFeature.tabularFigures()]),
              maxLines: 1,
            ),
            (style == NotusAttribute.block.bulletList)
                ? SizedBox()
                : SizedBox(width: 8)
          ]));
    }

    if (padding != null) {
      bullet = Padding(padding: padding, child: bullet);
    }

    // TODO: toggle with canEdit
    if (true) {
      bullet = IgnorePointer(ignoring: true, child: bullet);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: (indent * 32).toDouble()),
        bullet,
        Expanded(child: content)
      ],
    );
  }
}

extension on NotusStyle {
  BlockTheme blockTheme(BuildContext context) {
    if (contains(NotusAttribute.block.numberList)) {
      return ZefyrTheme.of(context).attributeTheme.numberList;
    } else if (contains(NotusAttribute.checkbox.checked)) {
      return ZefyrTheme.of(context).attributeTheme.checked;
    } else if (contains(NotusAttribute.checkbox.unchecked)) {
      return ZefyrTheme.of(context).attributeTheme.unchecked;
    }
    return ZefyrTheme.of(context).attributeTheme.bulletList;
  }
}

extension on NotusAttribute {
  String bulletText(int index, int indent) {
    if (this == NotusAttribute.block.numberList) {
      // a ~ z, aa ~ az, ba ~ bz ... aaa ~ aaz
      if ((indent % 3) == 1) {
        var chars = '';
        chars += String.fromCharCode(0x61 + (index - 1) % 26);
        while ((index - 1) ~/ 26 > 0) {
          index = (index - 1) ~/ 26;
          chars = String.fromCharCode(0x61 + (index - 1) % 26) + chars;
        }
        return chars + '.';
      }
      // i, ii, iii, iv, v, vi
      if ((indent % 3) == 2) {
        return index.toRomanNumeralString().toLowerCase() + '.';
      }
      // not allow over 1000
      index = index % 1000;
      return '$index.';
    }
    if ((indent % 3) == 1) return '○';
    if ((indent % 3) == 2) return '■';
    return '●';
  }
}
