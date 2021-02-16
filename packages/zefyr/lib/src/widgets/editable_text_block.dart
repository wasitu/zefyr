import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:notus/notus.dart';
import 'package:numerus/numerus.dart';

import '../rendering/editable_text_block.dart';
import 'cursor.dart';
import 'editable_text_line.dart';
import 'editor.dart';
import 'text_line.dart';
import 'theme.dart';

class EditableTextBlock extends StatelessWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final VerticalSpacing spacing;
  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets contentPadding;
  final ZefyrEmbedBuilder embedBuilder;

  EditableTextBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    @required this.spacing,
    @required this.cursorController,
    @required this.selection,
    @required this.selectionColor,
    @required this.enableInteractiveSelection,
    @required this.hasFocus,
    this.contentPadding,
    @required this.embedBuilder,
  })  : assert(hasFocus != null),
        assert(embedBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final theme = ZefyrTheme.of(context);
    return _EditableBlock(
      node: node,
      textDirection: textDirection,
      padding: spacing,
      contentPadding: contentPadding,
      decoration: _getDecorationForBlock(node, theme) ?? BoxDecoration(),
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final count = node.children.length;
    final children = <Widget>[];
    final indexes = {0: 0};
    var index = 0;
    var currentIndent = 0;
    for (final line in node.children) {
      index++;
      final indent =
          (line as LineNode)?.style?.get(NotusAttribute.indent)?.value ?? 0;
      if (currentIndent < indent) {
        indexes[indent] = 1;
      } else {
        indexes[indent] += 1;
      }
      currentIndent = indent;

      children.add(EditableTextLine(
        node: line,
        textDirection: textDirection,
        spacing: _getSpacingForLine(line, index, count, theme),
        leading: _buildLeading(context, line, indexes[indent], count, indent),
        indentWidth: _getIndentWidth(indent),
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        body: TextLine(
          node: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
        ),
        cursorController: cursorController,
        selection: selection,
        selectionColor: selectionColor,
        enableInteractiveSelection: enableInteractiveSelection,
        hasFocus: hasFocus,
      ));
    }
    return children.toList(growable: false);
  }

  Widget _buildLeading(
      BuildContext context, LineNode node, int index, int count, int indent) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.numberList) {
      return _NumberPoint(
        index: index,
        count: count,
        style: theme.paragraph.style,
        width: 32.0,
        padding: 8.0,
        indent: indent,
      );
    } else if (block == NotusAttribute.block.bulletList) {
      return _BulletPoint(
        style: theme.paragraph.style.copyWith(fontWeight: FontWeight.bold),
        width: 32,
        indent: indent,
      );
    } else if (block == NotusAttribute.block.code) {
      return _NumberPoint(
        index: index,
        count: count,
        style: theme.code.style
            .copyWith(color: theme.code.style.color.withOpacity(0.4)),
        width: 32.0,
        padding: 16.0,
        withDot: false,
      );
    }

    final checkbox = node.style.get(NotusAttribute.checkbox);
    if (checkbox == NotusAttribute.checkbox.checked) {
      return Container(
        alignment: AlignmentDirectional.topEnd,
        child: Checkbox(
          value: true,
          onChanged: (value) {
            // src/widgets/editor.dart :: _handleComponent
          },
        ),
        height: 24 * MediaQuery.of(context).textScaleFactor,
        padding: EdgeInsetsDirectional.only(end: 8, start: indent * 32.0),
      );
    } else if (checkbox == NotusAttribute.checkbox.unchecked) {
      return Container(
        alignment: AlignmentDirectional.topEnd,
        child: Checkbox(
          value: false,
          onChanged: (value) {
            // src/widgets/editor.dart :: _handleComponent
          },
        ),
        height: 24 * MediaQuery.of(context).textScaleFactor,
        padding: EdgeInsetsDirectional.only(end: 8, start: indent * 32.0),
      );
    }
    return null;
  }

  double _getIndentWidth(int indent) {
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      return 16.0;
    } else if (block == NotusAttribute.block.code) {
      return 32.0;
    } else {
      return 32.0 + 32.0 * indent.toDouble();
    }
  }

  VerticalSpacing _getSpacingForLine(
      LineNode node, int index, int count, ZefyrThemeData theme) {
    final heading = node.style.get(NotusAttribute.heading);

    var top = 0.0;
    var bottom = 0.0;

    if (heading == NotusAttribute.heading.level1) {
      top = theme.heading1.spacing.top;
      bottom = theme.heading1.spacing.bottom;
    } else if (heading == NotusAttribute.heading.level2) {
      top = theme.heading2.spacing.top;
      bottom = theme.heading2.spacing.bottom;
    } else if (heading == NotusAttribute.heading.level3) {
      top = theme.heading3.spacing.top;
      bottom = theme.heading3.spacing.bottom;
    } else {
      final block = this.node.style.get(NotusAttribute.block);
      var lineSpacing;
      if (block == NotusAttribute.block.quote) {
        lineSpacing = theme.quote.lineSpacing;
      } else if (block == NotusAttribute.block.numberList ||
          block == NotusAttribute.block.bulletList) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.block.code ||
          block == NotusAttribute.block.code) {
        lineSpacing = theme.lists.lineSpacing;
      }

      final checkbox = this.node.style.get(NotusAttribute.checkbox);
      if (this.node is CheckboxNode) {
        lineSpacing = theme.lists.lineSpacing;
      }
      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
    }

    // If this line is the top one in this block we ignore its top spacing
    // because the block itself already has it. Similarly with the last line
    // and its bottom spacing.
    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(top: top, bottom: bottom);
  }

  BoxDecoration _getDecorationForBlock(BlockNode node, ZefyrThemeData theme) {
    final style = node.style.get(NotusAttribute.block);
    if (style == NotusAttribute.block.quote) {
      return theme.quote.decoration;
    } else if (style == NotusAttribute.block.code) {
      return theme.code.decoration;
    }
    return null;
  }
}

class _EditableBlock extends MultiChildRenderObjectWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final VerticalSpacing padding;
  final Decoration decoration;
  final EdgeInsets contentPadding;

  _EditableBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    this.padding = const VerticalSpacing(),
    this.contentPadding,
    @required this.decoration,
    @required List<Widget> children,
  }) : super(key: key, children: children);

  EdgeInsets get _padding =>
      EdgeInsets.only(top: padding.top, bottom: padding.bottom);

  EdgeInsets get _contentPadding => contentPadding ?? EdgeInsets.zero;

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      node: node,
      textDirection: textDirection,
      padding: _padding,
      decoration: decoration,
      contentPadding: _contentPadding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject.node = node;
    renderObject.textDirection = textDirection;
    renderObject.padding = _padding;
    renderObject.decoration = decoration;
    renderObject.contentPadding = _contentPadding;
  }
}

class _NumberPoint extends StatelessWidget {
  final int index;
  final int count;
  final int indent;
  final TextStyle style;
  final double width;
  final bool withDot;
  final double padding;

  const _NumberPoint({
    Key key,
    @required this.index,
    @required this.count,
    @required this.style,
    @required this.width,
    this.indent = 0,
    this.withDot = true,
    this.padding = 0.0,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      child: Text(withDot ? '${display()}.' : '${display()}',
          style: style.apply(fontFeatures: [FontFeature.tabularFigures()])),
      width: width + indent * 32.0,
      padding: EdgeInsetsDirectional.only(end: padding, start: indent * 32.0),
    );
  }

  String display() {
    var index = this.index;
    // a ~ z, aa ~ az, ba ~ bz ... aaa ~ aaz
    if ((indent % 3) == 1) {
      var chars = '';
      chars += String.fromCharCode(0x61 + (index - 1) % 26);
      while ((index - 1) ~/ 26 > 0) {
        index = (index - 1) ~/ 26;
        chars = String.fromCharCode(0x61 + (index - 1) % 26) + chars;
      }
      return chars;
    }
    // i, ii, iii, iv, v, vi
    if ((indent % 3) == 2) {
      return index.toRomanNumeralString().toLowerCase();
    }
    // not allow over 1000
    index = index % 1000;
    return '$index';
  }
}

class _BulletPoint extends StatelessWidget {
  final TextStyle style;
  final double width;
  final int indent;

  const _BulletPoint({
    Key key,
    @required this.style,
    @required this.width,
    this.indent = 0,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      child: Text('${display()}', style: style),
      width: width + indent * 32.0,
      padding: EdgeInsetsDirectional.only(end: 8, start: indent * 32.0),
    );
  }

  String display() {
    if ((indent % 3) == 1) return '○';
    if ((indent % 3) == 2) return '■';
    return '●';
  }
}
