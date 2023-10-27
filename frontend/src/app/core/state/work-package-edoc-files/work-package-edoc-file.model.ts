export interface IWorkPackageEdocFileUpload {
  /**
   * 文件
   */
  file:File;
  /**
   * 上传进度
   */
  progress:number;
  /**
   * 上传状态，0: 等待, 1: 上传中, 2: 上传完成, -1: 上传失败
   */
  status:0 | 1 | 2 | -1;
}
