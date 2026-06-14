import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeHighlighter {
  static TextSpan highlight({
    required String code,
    required String language,
    required BuildContext context,
    required TextStyle baseStyle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonious curated colors matching the premium app aesthetics
    final keywordColor = isDark ? const Color(0xFFFF9E64) : const Color(0xFFE06C75); // orange / soft red
    final stringColor = isDark ? const Color(0xFF9ECE6A) : const Color(0xFF98C379); // green
    final commentColor = isDark ? const Color(0xFF565F89) : const Color(0xFFABB2BF); // slate / grey
    final numberColor = isDark ? const Color(0xFFBB9AF7) : const Color(0xFFD19A66); // purple / orange-brown
    // List of regex patterns and their matching styles
    final keywords = {
      'c++': [
        '#include', '#define', '#ifdef', '#ifndef', '#endif', 'void', 'int', 'double', 'float', 'char', 'bool', 
        'class', 'struct', 'public', 'private', 'protected', 'return', 'if', 'else', 'for', 'while', 'do', 
        'switch', 'case', 'break', 'continue', 'default', 'new', 'delete', 'const', 'static', 'namespace', 
        'using', 'std', 'vector', 'string', 'cout', 'cin', 'endl', 'template', 'typename', 'virtual', 'override'
      ],
      'python': [
        'def', 'class', 'return', 'if', 'elif', 'else', 'for', 'while', 'break', 'continue', 'import', 'from', 
        'as', 'in', 'is', 'not', 'and', 'or', 'lambda', 'try', 'except', 'finally', 'raise', 'assert', 'pass', 
        'global', 'nonlocal', 'with', 'yield', 'print', 'len', 'range', 'list', 'dict', 'set', 'tuple', 'str', 
        'int', 'float', 'bool'
      ],
      'java': [
        'public', 'private', 'protected', 'class', 'interface', 'extends', 'implements', 'import', 'package', 
        'void', 'int', 'double', 'float', 'boolean', 'char', 'byte', 'short', 'long', 'static', 'final', 
        'abstract', 'synchronized', 'volatile', 'transient', 'native', 'strictfp', 'return', 'if', 'else', 
        'for', 'while', 'do', 'switch', 'case', 'break', 'continue', 'default', 'new', 'this', 'super', 
        'try', 'catch', 'finally', 'throw', 'throws', 'instanceof', 'String', 'System', 'out', 'println'
      ],
      'javascript': [
        'var', 'let', 'const', 'function', 'return', 'if', 'else', 'for', 'while', 'do', 'switch', 'case', 
        'break', 'continue', 'default', 'class', 'new', 'this', 'super', 'import', 'export', 'from', 
        'try', 'catch', 'finally', 'throw', 'typeof', 'instanceof', 'in', 'of', 'async', 'await', 
        'console', 'log', 'Promise', 'resolve', 'reject'
      ],
      'dart': [
        'void', 'int', 'double', 'num', 'bool', 'String', 'List', 'Map', 'Set', 'var', 'final', 'const', 
        'late', 'dynamic', 'class', 'mixin', 'extension', 'extends', 'with', 'implements', 'import', 
        'export', 'part', 'of', 'show', 'hide', 'as', 'library', 'external', 'static', 'factory', 
        'get', 'set', 'operator', 'return', 'if', 'else', 'for', 'in', 'while', 'do', 'switch', 'case', 
        'break', 'continue', 'default', 'new', 'this', 'super', 'try', 'on', 'catch', 'finally', 
        'throw', 'rethrow', 'async', 'await', 'yield', 'assert', 'print'
      ],
    }[language.toLowerCase()] ?? [];

    if (code.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final keywordPattern = keywords.isNotEmpty
        ? '\\b(?:${keywords.map(RegExp.escape).join('|')})\\b'
        : '';
    
    final String regexSrc;
    if (language.toLowerCase() == 'python') {
      regexSrc = '(#.*)|('
          '["\']{3}[\\s\\S]*?["\']{3}'
          '|"(?:\\\\.|[^"\\\\])*"'
          '|\'(?:\\\\.|[^\'\\\\])*\''
          ')|($keywordPattern)|(\\b\\d+\\b)';
    } else {
      regexSrc = '(\\/\\/.*|\\/\\*[\\s\\S]*?\\*\\/)|('
          '"(?:\\\\.|[^"\\\\])*"'
          '|\'(?:\\\\.|[^\'\\\\])*\''
          ')|($keywordPattern)|(\\b\\d+\\b)';
    }

    final regExp = RegExp(regexSrc);
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in regExp.allMatches(code)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final text = match.group(0)!;
      TextStyle style = baseStyle;

      if (match.group(1) != null) {
        // Comment
        style = baseStyle.copyWith(color: commentColor, fontStyle: FontStyle.italic);
      } else if (match.group(2) != null) {
        // String
        style = baseStyle.copyWith(color: stringColor);
      } else if (match.group(3) != null) {
        // Keyword
        style = baseStyle.copyWith(color: keywordColor, fontWeight: FontWeight.bold);
      } else if (match.group(4) != null) {
        // Number
        style = baseStyle.copyWith(color: numberColor);
      }

      spans.add(TextSpan(text: text, style: style));
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  static List<TextSpan> splitHighlightedLines(TextSpan highlightedSpan, TextStyle baseStyle) {
    final List<List<InlineSpan>> lines = [[]];

    void traverse(InlineSpan currentSpan, TextStyle parentStyle) {
      final currentStyle = (currentSpan.style != null)
          ? parentStyle.merge(currentSpan.style)
          : parentStyle;

      if (currentSpan is TextSpan) {
        final text = currentSpan.text;
        if (text != null) {
          final parts = text.split('\n');
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              lines.last.add(TextSpan(text: parts[i], style: currentStyle));
            }
            if (i < parts.length - 1) {
              lines.add([]);
            }
          }
        }
        if (currentSpan.children != null) {
          for (final child in currentSpan.children!) {
            traverse(child, currentStyle);
          }
        }
      }
    }

    traverse(highlightedSpan, baseStyle);

    return lines.map((lineSpans) => TextSpan(children: lineSpans, style: baseStyle)).toList();
  }
}

class CodeEditingController extends TextEditingController {
  String language;

  CodeEditingController({super.text, required this.language});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return CodeHighlighter.highlight(
      code: text,
      language: language,
      context: context,
      baseStyle: style ?? const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }
}

class CodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if a single character was inserted and it is a newline
    if (newValue.text.length > oldValue.text.length) {
      final int addedOffset = newValue.selection.extentOffset;
      if (addedOffset > 0 && newValue.text[addedOffset - 1] == '\n') {
        // Extract the previous line before this cursor position
        final String textBeforeCursor = newValue.text.substring(0, addedOffset - 1);
        final int lastNewLine = textBeforeCursor.lastIndexOf('\n');
        final String lastLine = lastNewLine == -1
            ? textBeforeCursor
            : textBeforeCursor.substring(lastNewLine + 1);

        // Calculate current indentation of the previous line
        final int spaceCount = lastLine.length - lastLine.trimLeft().length;
        String indent = lastLine.substring(0, spaceCount);
        
        // Auto-indent further if previous line ends with block opening structures ({, :, or [)
        final String trimmedLastLine = lastLine.trim();
        if (trimmedLastLine.endsWith('{') || trimmedLastLine.endsWith(':') || trimmedLastLine.endsWith('[')) {
          indent += '  '; // Append 2 spaces
        }
        
        if (indent.isNotEmpty) {
          final String newText = newValue.text.substring(0, addedOffset) +
              indent +
              newValue.text.substring(addedOffset);
          
          final int newOffset = addedOffset + indent.length;
          
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newOffset),
          );
        }
      }
    }
    return newValue;
  }
}
