type Task<T=unknown> = (
  lastResult:unknown,
  setComplete:() => void,
  setError:() => void
) => Promise<T>;

// 0: 初始化, 1: running, 2: completed, -1: error
type Status = -1 | 0 | 1 | 2;

export type ProgressInfo = {
  total:number;
  current:number;
  result:unknown;
  task:Task;
};

export class PromiseTaskQueue {
  private tasks:Task[] = [];

  private total = 0;

  private current = 0;

  private status:Status = 0;

  private result:unknown = undefined;

  private error:unknown = undefined;

  private startHandler?:() => void;

  private finishHandler?:() => void;

  private completeHandler?:() => void;

  private errorHandler?:(error:unknown) => void;

  private progressHandler?:(info:ProgressInfo) => void;

  private resolve?:(result:unknown) => void;

  private reject?:(err:unknown) => void;

  public add(task:Task) {
    if (!this.isStart) throw new Error('任务队列已运行或已完成');
    this.tasks.push(task);
    return this;
  }

  private getCurrentTask() {
    this.current+=1;
    return this.tasks.shift();
  }

  public start = <T=unknown>() => {
    this.setStart();

    return new Promise<T>((res, rej) => {
      this.resolve = res;
      this.reject = rej;
      void this.runTask();
    });
  };

  private runTask = async () => {
    const task = this.getCurrentTask();

    if (!task) {
      this.setCompleted();
      return;
    }

    try {
      this.result = await task(this.result, this.setCompleted, this.setError);

      this.progressHandler?.({
        total: this.total,
        current: this.current,
        result: this.result,
        task,
      });

      if (this.isCompleted) {
        this.setCompleted();
      } else {
        await this.runTask();
      }
    } catch (err) {
      this.error = err;
      this.setError();
    }
  };

  public get isStart() {
    return this.status === 0;
  }

  public get isRunning() {
    return this.status === 1;
  }

  public get isCompleted() {
    return this.status === 2;
  }

  public get isError() {
    return this.status === -1;
  }

  public get isFinished() {
    return this.isCompleted || this.isError;
  }

  public onStart(handler:typeof this.startHandler) {
    this.startHandler = handler;
  }

  public onFinish(handler:typeof this.finishHandler) {
    this.finishHandler = handler;
  }

  public onComplete(handler:typeof this.completeHandler) {
    this.completeHandler = handler;
  }

  public onError(handler:typeof this.errorHandler) {
    this.errorHandler = handler;
  }

  public onProgress(handler:typeof this.progressHandler) {
    this.progressHandler = handler;
  }

  public reset(handlers = false) {
    if (this.isRunning) throw new Error('任务队列正在运行中，不能重置');

    this.current = 0;
    this.total = 0;
    this.tasks = [];
    this.status = 0;
    this.result = undefined;
    this.resolve = undefined;
    this.reject = undefined;
    if (handlers) {
      this.startHandler = undefined;
      this.finishHandler = undefined;
      this.completeHandler = undefined;
      this.errorHandler = undefined;
      this.progressHandler = undefined;
    }
  }

  private setStart = () => {
    if (!this.isStart) throw new Error('任务队列已运行或已完成');
    if (this.tasks.length === 0) throw new Error('任务列表为空');

    this.total = this.tasks.length;
    this.status = 1;
    this.resolve = undefined;
    this.reject = undefined;
    this.startHandler?.();
  };

  private setCompleted = () => {
    if (!this.isRunning) return;
    this.status = 2;
    this.completeHandler?.();
    this.finishHandler?.();
    this.resolve?.(this.result);
    this.resolve = undefined;
    this.reject = undefined;
  };

  private setError = () => {
    if (!this.isRunning) return;
    this.status = -1;
    this.errorHandler?.(this.error);
    this.reject?.(this.error);
    this.resolve = undefined;
    this.reject = undefined;
  };
}
