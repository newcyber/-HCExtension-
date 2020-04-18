--[[ <HCExtension>
@name          Save and Hit by Last-Modified (raw)
@author        reges007
@version       1
@description   Cache-control by Last-Modified, berfungsi menggantikan peran menu 'save to cache' dan 'don't update' namun dalam kasus tertentu masih diperlukan secara manual. 
@exception     ^.*(googlevideo|youtube).com/videoplayback.*
@exception     \.action$
@exception     ^.*(google.com/market/GetBinary/.*)\?.*
@exception     ^.+.(captcha|mrtg|cgi-bin|notice|announce).*
@rule          ^(.*\.[a-z|0-9|\-]{2,15})(\?|&|$)
@event         AnswerHeaderReceived/save
</HCExtension> ]]

function GetAnswerCode(s)
  _,_,x = string.find(s, 'HTTP/1%.%d +(%d+)')
  if x==nil then return -1 else return tonumber(x) end
end

function cek_file(s)
   local f=io.open(s,"r")
	if f~=nil then io.close(f) return true
   else return false
   end
end

function save()

         local code = GetAnswerCode(hc.answer_header)

             if hc.method == 'GET' and code==200 then
                local file = hc.get_cache_file_name(hc.url)
                local dir =  re.replace(file, [[^(.*)]], [[\1.txt]])           -- destination log adalah sama pathnya dengan destination konten, untuk membedakan log dng konten dikasih akhiran .txt
                local dir =  re.replace(dir, [[(\w:\\)]], '')            
                local dir =  re.replace(dir, [[(Cache\\)]], '')
                local lmdf = re.find(hc.answer_header, [[^Last-Modified:\s([^\r\n]+)]]) -- mengambil variabel dimulai dari Last-modified
                local lmdf = re.replace(lmdf, [[Last-Modified:\s]], '', true)  -- membuang karakter yang tidak diperlukan
                local lmdf = re.replace(lmdf, [[([\s,:])]], '', true)          -- membuang karakter yang tidak diperlukan
                local path = hc.cache_path ..dir -- log last-modified disimpan sesuai path kontennya
                   
                    if cek_file(path) == false or hc.cache_file_name== '' then -- jika log atau cache kontennya kosong script mulai menulis log dan menyimpan konten
                           hc.prepare_path(path)
                         local tls = io.open(path, "w")
                               tls:write(lmdf)
                               tls:close()
                           hc.action = 'save-'
                           hc.monitor_string = hc.monitor_string.. 'SAVE.NEW-FILE'
                    else                                                       -- jika log dan cache konten ada script memulai membaca data log last-modified 
                                hc.prepare_path(path)
                          local baca = io.open(path, "r")
                          local cek = baca:read('*a')

                              if cek == lmdf and hc.cache_file_name==file then -- script melakukan pengecekan data log last-modified dengan data last-modified dari server/internet 
                                 baca:close()                                  -- jika data sama script melakukan action don't update aka hit cache
                                 hc.action = 'dont_update-'
                                 hc.monitor_string = hc.monitor_string.. 'Hit-Cache Last-Modified'
                              else                                           -- jika log ada dan konten kosong atau konten ada dan log kosong
                                 hc.prepare_path(path)                       -- atau data last-modified berubah dari server/internet script memulai tulis ulang log dan simpan new konten atau update konten  
                                 local tls = io.open(path, "w")
                                       tls:write(lmdf)
                                       tls:close()
                                  hc.action = 'save-'
                                  hc.monitor_string = hc.monitor_string.. 'SAVE.UPDATE-FILE'
                              end
                    end
             end
             
end

-- Extension ini hanya untuk penggunaan reguler saja alias static contents, yaitu kerpeluan browsing dan web based games atau pc games online yang algorithmanya tidak rumit.
-- Untuk penggunaan expert seperti dynamic content (youtube dll) dan algorithma games yang rumit (elsword,garena dll) hanya khusus pembeli saja.
-- Silahkan edit sesuai keperluan Anda tanpa merubah credit.
-- Dengan membaca ini atau menggunakan Extension ini Anda setuju jika terjadi kelainan atau kerusakan adalah diluar tanggung jawab penulis (reges007) .