export type Product={id:string;name:string;sku:string;barcode:string;category:string;buy:number;sell:number;stock:number;minStock:number;unit:string;createdAt:number;updatedAt:number};
export type Customer={id:string;name:string;phone:string;due:number;createdAt:number};
export type SaleItem={productId:string;name:string;qty:number;price:number};
export type Sale={id:string;invoice:string;customerId:string;customerName:string;payment:"Cash"|"UPI"|"Card"|"Credit";items:SaleItem[];subtotal:number;discount:number;total:number;createdAt:number};
export type PurchaseItem={productId:string;qty:number;cost:number};
export type Purchase={id:string;supplier:string;invoice:string;items:PurchaseItem[];total:number;createdAt:number};
export type State={products:Product[];customers:Customer[];sales:Sale[];purchases:Purchase[];settings:{shop:string;phone:string;address:string;currency:string;prefix:string}};
const KEY="sinvo-state-v1";const empty:State={products:[],customers:[],sales:[],purchases:[],settings:{shop:"My Shop",phone:"",address:"",currency:"₹",prefix:"INV"}};
const req=<T,>(r:IDBRequest<T>)=>new Promise<T>((ok,no)=>{r.onsuccess=()=>ok(r.result);r.onerror=()=>no(r.error)});
let memory:State|null=null;
export async function load():Promise<State>{if(memory)return structuredClone(memory);if(!("indexedDB"in window)){const x=localStorage.getItem(KEY);return memory=x?JSON.parse(x):structuredClone(empty)}
return new Promise((resolve,reject)=>{const o=indexedDB.open("sinvo",1);o.onupgradeneeded=()=>o.result.createObjectStore("state");o.onsuccess=async()=>{try{const db=o.result;const tx=db.transaction("state","readonly");const v=await req(tx.objectStore("state").get("main"));memory=v?JSON.parse(v):structuredClone(empty);resolve(structuredClone(memory))}catch(e){reject(e)}};o.onerror=()=>reject(o.error)})}
export async function save(s:State){memory=structuredClone(s);if(!("indexedDB"in window)){localStorage.setItem(KEY,JSON.stringify(s));return}
const db=await new Promise<IDBDatabase>((resolve,reject)=>{const o=indexedDB.open("sinvo",1);o.onupgradeneeded=()=>o.result.createObjectStore("state");o.onsuccess=()=>resolve(o.result);o.onerror=()=>reject(o.error)});const tx=db.transaction("state","readwrite");tx.objectStore("state").put(JSON.stringify(s),"main");await new Promise<void>((ok,no)=>{tx.oncomplete=()=>ok();tx.onerror=()=>no(tx.error)})}
export function id(){return crypto.randomUUID()} export function money(n:number,c="₹"){return c+Number(n||0).toLocaleString("en-IN",{minimumFractionDigits:2,maximumFractionDigits:2})}
export function exportState(s:State){const b=new Blob([JSON.stringify(s,null,2)],{type:"application/json"});const a=document.createElement("a");a.href=URL.createObjectURL(b);a.download="sinvo-backup.json";a.click();URL.revokeObjectURL(a.href)}
export function importState(file:File):Promise<State>{return file.text().then(t=>{const x=JSON.parse(t);if(!x.products||!x.sales||!x.settings)throw Error("Invalid Sinvo backup");return x})}