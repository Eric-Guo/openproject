declare module 'typing' {
  import BigNumber from 'bignumber.js';

  export type Numeric = BigNumber | string | number;
}

declare module 'spark-md5' {
  interface SparkMd5ArrayBufferInstance {
    append(buffer:ArrayBuffer):void;
    end(raw?:boolean):string;
  }

  interface SparkMd5Module {
    ArrayBuffer:new () => SparkMd5ArrayBufferInstance;
  }

  const SparkMD5:SparkMd5Module;

  export = SparkMD5;
}
