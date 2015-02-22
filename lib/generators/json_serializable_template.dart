part of source_gen.json_serial.generator;

const String template = r'''
{{#createFactory}}
  {{className}} _${{className}}FromJson(Map json) => new {{className}}(
      {{#ctorArgs}}
        {{#named}}{{name}}: {{/named}}{{{value}}}{{#printComma}},{{/printComma}}
      {{/ctorArgs}}
  )
  {{#ctorFieldsToSet}}
    ..{{name}} = {{{value}}}
  {{/ctorFieldsToSet}}
  ;
{{/createFactory}}

{{#createToJson}}
  abstract class _${{className}}SerializerMixin {
    
    {{#fields}}
    {{type}} get {{name}};
    {{/fields}}
    
    Map<String, dynamic> toJson() => <String, dynamic>{
      {{#fields}}
      '{{name}}': {{{value}}}{{#printComma}},{{/printComma}}
      {{/fields}}
    };
  }
{{/createToJson}}
''';