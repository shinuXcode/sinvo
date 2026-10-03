export type BarcodeLookupProduct={title:string;brand:string;model:string;category:string;description:string;image:string;barcode:string};
const CACHE_KEY="sinvo-barcode-lookup-v1";
const normalizeCode=(v:string)=>v.trim().replace(/\s+/g,"");
export async function lookupProductByBarcode(input:string):Promise<BarcodeLookupProduct|null>{
 const code=normalizeCode(input);if(!code)return null;
 try{const cached=JSON.parse(localStorage.getItem(CACHE_KEY)||"{}")?.[code];if(cached)return cached}catch{}
 const controller=new AbortController(),timer=window.setTimeout(()=>controller.abort(),8000);
 try{
  const res=await fetch("https://api.upcitemdb.com/prod/trial/lookup?upc="+encodeURIComponent(code),{headers:{Accept:"application/json"},signal:controller.signal});
  if(res.status===404)return null;if(!res.ok)throw new Error("Barcode lookup service unavailable");
  const item=(await res.json())?.items?.[0];if(!item)return null;
  const value={title:String(item.title||"").trim(),brand:String(item.brand||"").trim(),model:String(item.model||"").trim(),category:String(item.category||"").split(">").slice(-1)[0].trim(),description:String(item.description||"").trim(),image:String(item.images?.[0]||"").trim(),barcode:String(item.ean||item.upc||item.gtin||code).trim()};
  if(!value.title&&!value.brand&&!value.model)return null;
  try{const all=JSON.parse(localStorage.getItem(CACHE_KEY)||"{}");all[code]=value;localStorage.setItem(CACHE_KEY,JSON.stringify(all))}catch{}
  return value;
 }finally{window.clearTimeout(timer)}
}