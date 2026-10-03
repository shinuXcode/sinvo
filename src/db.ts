export type Product={id:string;name:string;brand:string;model:string;sku:string;barcode:string;category:string;buy:number;sell:number;stock:number;minStock:number;unit:string;createdAt:number;updatedAt:number};
export type SaleItem={productId:string;name:string;qty:number;price:number};
export type Sale={id:string;invoice:string;payment:"Cash"|"UPI"|"Card";items:SaleItem[];subtotal:number;discount:number;total:number;createdAt:number};
export type PurchaseItem={productId:string;qty:number;cost:number};
export type Purchase={id:string;supplier:string;invoice:string;items:PurchaseItem[];total:number;createdAt:number};
export type State={products:Product[];sales:Sale[];purchases:Purchase[];settings:{shop:string;phone:string;address:string;currency:string;prefix:string;theme:"system"|"dark"|"light"|"midnight"|"ocean"|"emerald"|"sunset"|"paper"|"amoled";billTitle:string;billFooter:string;billExtra:string;showPhone:boolean;showAddress:boolean}};
const KEY="sinvo-state-v2";const empty:State={products:[],sales:[],purchases:[],settings:{shop:"My Shop",phone:"",address:"",currency:"₹",prefix:"INV",theme:"system",billTitle:"",billFooter:"Thank you for your business",billExtra:"",showPhone:true,showAddress:true}};
const clone=<T,>(x:T):T=>structuredClone(x);let memory:State|null=null;
function normalize(x:any):State{const base:any=clone(empty);Object.assign(base,x||{});base.products=Array.isArray(base.products)?base.products.map((p:any)=>({...p,brand:typeof p.brand==="string"?p.brand:"",model:typeof p.model==="string"?p.model:""})):[];base.sales=Array.isArray(base.sales)?base.sales:[];base.purchases=Array.isArray(base.purchases)?base.purchases:[];base.settings={...empty.settings,...(x?.settings||{})};if(!["system","dark","light","midnight","ocean","emerald","sunset","paper","amoled"].includes(base.settings.theme))base.settings.theme="system";base.sales=base.sales.map((sale:any)=>({...sale,payment:sale.payment==="Credit"?"Cash":sale.payment}));return base}
function idb():Promise<IDBDatabase>{return new Promise((resolve,reject)=>{const o=indexedDB.open("sinvo",2);o.onupgradeneeded=()=>{if(!o.result.objectStoreNames.contains("state"))o.result.createObjectStore("state")};o.onsuccess=()=>resolve(o.result);o.onerror=()=>reject(o.error)})}
export async function load():Promise<State>{if(memory)return clone(memory);if(!("indexedDB"in window)){try{const raw=localStorage.getItem(KEY)||localStorage.getItem("sinvo-state-v1");memory=normalize(raw?JSON.parse(raw):empty)}catch{memory=clone(empty)}return clone(memory)}
try{const db=await idb();const tx=db.transaction("state","readonly");const r=tx.objectStore("state").get("main");const v=await new Promise<any>((ok,no)=>{r.onsuccess=()=>ok(r.result);r.onerror=()=>no(r.error)});memory=normalize(v?JSON.parse(v):empty);return clone(memory)}catch{memory=clone(empty);return clone(memory)}}
export async function save(s:State){memory=normalize(s);if(!("indexedDB"in window)){localStorage.setItem(KEY,JSON.stringify(memory));return}const db=await idb();const tx=db.transaction("state","readwrite");tx.objectStore("state").put(JSON.stringify(memory),"main");await new Promise<void>((ok,no)=>{tx.oncomplete=()=>ok();tx.onerror=()=>no(tx.error)})}
export function id(){return crypto.randomUUID()}export function money(n:number,c="₹"){return c+Number(n||0).toLocaleString("en-IN",{minimumFractionDigits:2,maximumFractionDigits:2})}
export function exportState(s:State){const b=new Blob([JSON.stringify(s,null,2)],{type:"application/json"});const a=document.createElement("a");a.href=URL.createObjectURL(b);a.download="sinvo-backup.json";a.click();URL.revokeObjectURL(a.href)}

function cleanKey(v:any){return String(v??"").replace(new RegExp("^"+String.fromCharCode(0xFEFF)),"").trim().toLowerCase().replace(/[\s_\-\/().]+/g,"")}
function pick(o:any,keys:string[]){const map:any={};Object.keys(o||{}).forEach(k=>map[cleanKey(k)]=o[k]);for(const k of keys){const v=map[cleanKey(k)];if(v!==undefined&&v!==null&&String(v).trim()!=="")return v}return ""}
function num(v:any){const n=Number(String(v??"").replace(/[^0-9.\-]/g,""));return Number.isFinite(n)?n:0}
function productFromExternal(raw:any):Product|null{
  if(!raw||typeof raw!=="object")return null;
  const name=String(pick(raw,["name","item name","itemname","product name","productname","item","product"])||"").trim();
  if(!name)return null;
  const now=Date.now();
  return {
    id:id(),name,brand:String(pick(raw,["brand","brand name","brandname"])||"").trim(),
    model:String(pick(raw,["model","size","size/weight","sizeweight","weight","variant"])||"").trim(),
    sku:String(pick(raw,["sku","item code","itemcode","code"])||"").trim(),
    barcode:String(pick(raw,["barcode","bar code","upc","qr","qrcode","qr code"])||"").trim(),
    category:String(pick(raw,["category","group","type"])||"").trim(),
    buy:num(pick(raw,["buy","buy price","buyprice","cost","cost price","costprice","purchase price","purchaseprice"])),
    sell:num(pick(raw,["sell","sale","sale price","saleprice","selling price","sellingprice","price","rate"])),
    stock:num(pick(raw,["stock","quantity","qty","item quantity","itemquantity"])),
    minStock:num(pick(raw,["min stock","minstock","minimum stock","minimumstock"])),
    unit:String(pick(raw,["unit","units"])||"pcs").trim()||"pcs",createdAt:now,updatedAt:now
  };
}
function findExternalItems(root:any):any[]{
  if(Array.isArray(root))return root;
  if(!root||typeof root!=="object")return [];
  for(const k of ["products","items","itemlist","productlist","pricelist","price list","catalog","catalogue","data"]){
    const v=root[k]??root[Object.keys(root).find(x=>cleanKey(x)===cleanKey(k))||""];
    if(Array.isArray(v)&&v.length)return v;
  }
  for(const v of Object.values(root)){
    if(Array.isArray(v)&&v.some((x:any)=>x&&typeof x==="object"&&pick(x,["name","item name","product name","item","product"])))return v;
  }
  return [];
}
function parseCsv(text:string):any[]{
  if(text.charCodeAt(0)===0xFEFF)text=text.slice(1);
  const rows:string[][]=[];let row:string[]=[],cell="",quoted=false;
  const firstLine=(()=>{let s="",q=false;for(let i=0;i<text.length;i++){const ch=text[i],next=text[i+1];if(ch==='"'){if(q&&next==='"'){s+='"';i++}else q=!q}else if((ch==='\\n'||ch==='\\r')&&!q)break;else s+=ch}return s})();
  const candidates=[",",";","\\t","|"];const delimiter=candidates.reduce((best,d)=>firstLine.split(d).length>firstLine.split(best).length?d:best,",");
  for(let i=0;i<text.length;i++){
    const ch=text[i],next=text[i+1];
    if(ch==='"'){
      if(quoted&&next==='"'){cell+='"';i++}else quoted=!quoted;
    }else if(ch===delimiter&&!quoted){
      row.push(cell);cell="";
    }else if((ch==='\\n'||ch==='\\r')&&!quoted){
      if(ch==='\\r'&&next==='\\n')i++;
      row.push(cell);
      if(row.some(x=>x.trim()))rows.push(row);
      row=[];cell="";
    }else cell+=ch;
  }
  if(cell.length||row.length){row.push(cell);if(row.some(x=>x.trim()))rows.push(row)}
  const headers=(rows.shift()||[]).map(x=>x.trim().replace(/^"|"$/g,""));
  return rows.map(r=>Object.fromEntries(headers.map((h,i)=>[h,(r[i]??"").trim()])));
}
export async function importMakePriceList(file:File):Promise<{products:Product[];format:"json"|"csv";source:string}>{
  const text=await file.text();const lower=file.name.toLowerCase();let raw:any[];
  const looksCsv=lower.endsWith(".csv")||lower.endsWith(".txt")||(!lower.endsWith(".json")&&text.split(/\r?\n/).slice(0,5).some(line=>line.includes(",")||line.includes(";")||line.includes("\\t")||line.includes("|")));
  if(looksCsv){raw=parseCsv(text);const products=raw.map(productFromExternal).filter(Boolean) as Product[];if(!products.length)throw Error("No product rows detected. Check CSV headers.");return {products,format:"csv",source:"Make Price List / CSV"}}
  let parsed:any;try{parsed=JSON.parse(text)}catch{throw Error("Unsupported backup format")}
  raw=findExternalItems(parsed);
  if(!raw.length&&Array.isArray(parsed?.products))raw=parsed.products;
  const products=raw.map(productFromExternal).filter(Boolean) as Product[];
  if(!products.length)throw Error("No compatible products found");
  return {products,format:"json",source:"Make Price List / backup"}
}
export function importState(file:File):Promise<State>{return file.text().then(t=>{const x=JSON.parse(t);if(!x.products||!x.sales||!x.settings)throw Error("Invalid Sinvo backup");return normalize(x)})}