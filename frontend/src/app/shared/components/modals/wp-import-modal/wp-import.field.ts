export const WpImportFields = [
  'id',
  'type',
  'subject',
  'description',
  'startDate',
  'customField6',
  'follows',
  'heels',
  'parent',
] as const;

export type WpImportField = typeof WpImportFields[number];

export const WpImportFieldsMap:Record<string, WpImportField> = {
  type: 'type',
  类型: 'type',
  id: 'id',
  编号: 'id',
  subject: 'subject',
  主题: 'subject',
  description: 'description',
  描述: 'description',
  customField6: 'customField6',
  备注: 'customField6',
  follows: 'follows',
  后置于: 'follows',
  heels: 'heels',
  后置紧跟于: 'heels',
  parent: 'parent',
  '隶属于(父)': 'parent',
  '隶属于（父）': 'parent',
  父: 'parent',
  startDate: 'startDate',
  开始日期: 'startDate',
};
