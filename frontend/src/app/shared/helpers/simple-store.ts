export type StoreSubscriber<T> = (store:T[]) => void;

export class SimpleStore<T> {
  private list:T[] = [];

  private subscribers:StoreSubscriber<T>[] = [];

  public subscribe(subscriber:StoreSubscriber<T>) {
    this.subscribers.push(subscriber);
    subscriber([...this.list]);
  }

  public unsubscribe(subscriber:StoreSubscriber<T>) {
    const index = this.subscribers.indexOf(subscriber);
    if (index > -1) {
      this.subscribers.splice(index, 1);
    }
  }

  private dispatchChange() {
    this.subscribers.forEach((subscriber) => {
      subscriber([...this.list]);
    });
  }

  public setAll(list:T[]) {
    this.list = [...list];
    this.dispatchChange();
  }

  public set(index:number, item:T) {
    this.list[index] = item;
    this.dispatchChange();
  }

  public add(...items:T[]) {
    this.list.push(...items);
    this.dispatchChange();
  }

  public update(index:number, handle:(item:T, index:number) => T) {
    const item = this.list[index];
    this.list[index] = handle(item, index);
    this.dispatchChange();
  }

  public remove(item:T) {
    const index = this.list.indexOf(item);
    if (index > -1) {
      this.list.splice(index, 1);
    }
    this.dispatchChange();
  }

  public clear() {
    this.list = [];
    this.dispatchChange();
  }

  public getAll() {
    return [...this.list];
  }
}
