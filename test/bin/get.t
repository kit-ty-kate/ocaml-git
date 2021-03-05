Extraction of Git objects
  $ carton.get ../carton/bomb.pack --raw 12
  tree c1971b07ce6888558e2178a121804774c4201b17
  parent 18ed56cbc5012117e24a603e7c072cf65d36d469
  author Kate Murphy <hello@kate.io> 1507821911 -0400
  committer GitHub <noreply@github.com> 1507821911 -0400
  
  Update README.md
  $ carton.get ../carton/bomb.pack --raw 18ed56cbc5012117e24a603e7c072cf65d36d469
  tree d9513477b01825130c48c4bebed114c4b2d50401
  parent 45546f17e5801791d4bc5968b91253a2f4b0db72
  author Kate Murphy <hello@kate.io> 1507821648 -0400
  committer GitHub <noreply@github.com> 1507821648 -0400
  
  Create Readme.md
  $ carton.get ../carton/bomb.pack c1971b07ce6888558e2178a121804774c4201b17
  00000000: 3130 3036 3434 2052 4541 444d 452e 6d64  100644 README.md
  00000010: 00ad 839b aae5 fc20 7ac0 db15 34ba 4819  ....... z...4.H.
  00000020: cbb4 a34b b934 3030 3030 2064 3000 8d10  ...K.40000 d0...
  00000030: 6ebc 17b2 de80 acef d454 825d 394b 9bc4  n........T.]9K..
  00000040: 7fe6 3430 3030 3020 6431 008d 106e bc17  ..40000 d1...n..
  00000050: b2de 80ac efd4 5482 5d39 4b9b c47f e634  ......T.]9K....4
  00000060: 3030 3030 2064 3200 8d10 6ebc 17b2 de80  0000 d2...n.....
  00000070: acef d454 825d 394b 9bc4 7fe6 3430 3030  ...T.]9K....4000
  00000080: 3020 6433 008d 106e bc17 b2de 80ac efd4  0 d3...n........
  00000090: 5482 5d39 4b9b c47f e634 3030 3030 2064  T.]9K....40000 d
  000000a0: 3400 8d10 6ebc 17b2 de80 acef d454 825d  4...n........T.]
  000000b0: 394b 9bc4 7fe6 3430 3030 3020 6435 008d  9K....40000 d5..
  000000c0: 106e bc17 b2de 80ac efd4 5482 5d39 4b9b  .n........T.]9K.
  000000d0: c47f e634 3030 3030 2064 3600 8d10 6ebc  ...40000 d6...n.
  000000e0: 17b2 de80 acef d454 825d 394b 9bc4 7fe6  .......T.]9K....
  000000f0: 3430 3030 3020 6437 008d 106e bc17 b2de  40000 d7...n....
  00000100: 80ac efd4 5482 5d39 4b9b c47f e634 3030  ....T.]9K....400
  00000110: 3030 2064 3800 8d10 6ebc 17b2 de80 acef  00 d8...n.......
  00000120: d454 825d 394b 9bc4 7fe6 3430 3030 3020  .T.]9K....40000 
  00000130: 6439 008d 106e bc17 b2de 80ac efd4 5482  d9...n........T.
  00000140: 5d39 4b9b c47f e6                        ]9K....
  $ carton.get --with-path --with-info ../carton/bomb.pack c1971b07ce6888558e2178a121804774c4201b17
  path:        279
               234
  depth:         2
  length:      327
  kind:          b
  
  00000000: 3130 3036 3434 2052 4541 444d 452e 6d64  100644 README.md
  00000010: 00ad 839b aae5 fc20 7ac0 db15 34ba 4819  ....... z...4.H.
  00000020: cbb4 a34b b934 3030 3030 2064 3000 8d10  ...K.40000 d0...
  00000030: 6ebc 17b2 de80 acef d454 825d 394b 9bc4  n........T.]9K..
  00000040: 7fe6 3430 3030 3020 6431 008d 106e bc17  ..40000 d1...n..
  00000050: b2de 80ac efd4 5482 5d39 4b9b c47f e634  ......T.]9K....4
  00000060: 3030 3030 2064 3200 8d10 6ebc 17b2 de80  0000 d2...n.....
  00000070: acef d454 825d 394b 9bc4 7fe6 3430 3030  ...T.]9K....4000
  00000080: 3020 6433 008d 106e bc17 b2de 80ac efd4  0 d3...n........
  00000090: 5482 5d39 4b9b c47f e634 3030 3030 2064  T.]9K....40000 d
  000000a0: 3400 8d10 6ebc 17b2 de80 acef d454 825d  4...n........T.]
  000000b0: 394b 9bc4 7fe6 3430 3030 3020 6435 008d  9K....40000 d5..
  000000c0: 106e bc17 b2de 80ac efd4 5482 5d39 4b9b  .n........T.]9K.
  000000d0: c47f e634 3030 3030 2064 3600 8d10 6ebc  ...40000 d6...n.
  000000e0: 17b2 de80 acef d454 825d 394b 9bc4 7fe6  .......T.]9K....
  000000f0: 3430 3030 3020 6437 008d 106e bc17 b2de  40000 d7...n....
  00000100: 80ac efd4 5482 5d39 4b9b c47f e634 3030  ....T.]9K....400
  00000110: 3030 2064 3800 8d10 6ebc 17b2 de80 acef  00 d8...n.......
  00000120: d454 825d 394b 9bc4 7fe6 3430 3030 3020  .T.]9K....40000 
  00000130: 6439 008d 106e bc17 b2de 80ac efd4 5482  d9...n........T.
  00000140: 5d39 4b9b c47f e6                        ]9K....