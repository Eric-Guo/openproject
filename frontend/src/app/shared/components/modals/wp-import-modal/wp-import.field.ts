export const WpImportFields = [
  'id',
  'type',
  'subject',
  'description',
  'customField6',
  'follows',
  'heels',
  'parent',
] as const;

export type WpImportField = typeof WpImportFields[number];

export const WpImportFieldsMap:Record<string, WpImportField> = {
  类型: 'type',
  编号: 'id',
  主题: 'subject',
  描述: 'description',
  备注: 'customField6',
  后置于: 'follows',
  后置紧跟于: 'heels',
  '隶属于(父)': 'parent',
  '隶属于（父）': 'parent',
  父: 'parent',
};
