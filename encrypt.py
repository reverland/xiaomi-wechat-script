#!/usr/bin/env python3

from pysqlcipher3 import dbapi2 as sqlite
import hashlib
from lxml import etree
import sys

root = etree.parse(sys.argv[1])
uin = root.xpath("int[@name='_auth_uin']/@value")[0]
print("uin: %s" % uin)
root = etree.parse(sys.argv[2])
imei = root.xpath("string[@name='IMEI_DENGTA']/text()")[0]
print("IMEI: %s" % imei)

key = hashlib.md5((imei + uin).encode('ascii')).digest().hex()[0:7]
print("cipher: %s" % key)

def decrypt( key ):
    conn = sqlite.connect(sys.argv[3])
    c = conn.cursor()
    c.execute( "ATTACH DATABASE '%s' AS wechatencrypted KEY '%s';" % (sys.argv[4], key) )
    c.execute( "PRAGMA wechatencrypted.cipher_use_hmac = OFF;" )
    c.execute( "PRAGMA wechatencrypted.cipher_page_size = 1024;" )
    c.execute( "PRAGMA wechatencrypted.kdf_iter = 4000;" )
    c.execute( "SELECT sqlcipher_export( 'wechatencrypted' );" )
    c.execute( "DETACH DATABASE wechatencrypted;" )
    c.close()
def main():
    print(key)
    decrypt( key )
main()
