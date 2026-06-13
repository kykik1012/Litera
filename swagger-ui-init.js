
window.onload = function() {
  // Build a system
  var url = window.location.search.match(/url=([^&]+)/);
  if (url && url.length > 1) {
    url = decodeURIComponent(url[1]);
  } else {
    url = window.location.origin;
  }
  var options = {
  "swaggerDoc": {
    "openapi": "3.0.0",
    "info": {
      "title": "PBM Litera API",
      "version": "1.0.0",
      "description": "API documentation PBM Litera"
    },
    "servers": [
      {
        "url": "https://api-litera-production.up.railway.app"
      }
    ],
    "components": {
      "securitySchemes": {
        "bearerAuth": {
          "type": "http",
          "scheme": "bearer",
          "bearerFormat": "JWT",
          "description": "Masukkan JWT Token dengan format: Bearer {token}"
        }
      }
    },
    "security": [
      {
        "bearerAuth": []
      }
    ],
    "paths": {
      "/api/users": {
        "get": {
          "summary": "Mengambil semua data user",
          "tags": [
            "Users"
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data user"
            }
          }
        }
      },
      "/api/users/{id}": {
        "get": {
          "summary": "Mengambil detail user berdasarkan id",
          "tags": [
            "Users"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail user"
            }
          }
        },
        "put": {
          "summary": "Update data user (Admin)",
          "tags": [
            "Users"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "username": {
                      "type": "string"
                    },
                    "email": {
                      "type": "string"
                    },
                    "role": {
                      "type": "integer"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "User berhasil diupdate"
            }
          }
        },
        "delete": {
          "summary": "Soft delete user",
          "tags": [
            "Users"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "User berhasil dihapus"
            }
          }
        }
      },
      "/api/users/profile/{id}": {
        "put": {
          "summary": "Update profile customer dan foto profile",
          "tags": [
            "Users"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": false,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "name": {
                      "type": "string",
                      "description": "Nama customer"
                    },
                    "profile_picture": {
                      "type": "string",
                      "format": "binary",
                      "description": "Foto profile"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Profile berhasil diupdate"
            },
            "404": {
              "description": "User tidak ditemukan"
            }
          }
        }
      },
      "/api/users/restore/{id}": {
        "put": {
          "summary": "Mengaktifkan kembali user",
          "tags": [
            "Users"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "User berhasil diaktifkan kembali"
            }
          }
        }
      },
      "/api/thematic-routes": {
        "get": {
          "summary": "Mengambil semua rute thematic",
          "tags": [
            "Thematic Routes"
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data rute thematic",
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "success": {
                        "type": "boolean"
                      },
                      "message": {
                        "type": "string"
                      },
                      "data": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "id": {
                              "type": "integer"
                            },
                            "judul_rute": {
                              "type": "string"
                            },
                            "deskripsi": {
                              "type": "string"
                            },
                            "image_url": {
                              "type": "string"
                            },
                            "is_delete": {
                              "type": "boolean"
                            },
                            "created_at": {
                              "type": "string"
                            },
                            "updated_at": {
                              "type": "string"
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "post": {
          "summary": "Menambahkan rute thematic",
          "tags": [
            "Thematic Routes"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "required": [
                    "judul_rute",
                    "deskripsi"
                  ],
                  "properties": {
                    "judul_rute": {
                      "type": "string",
                      "example": "Wisata Laksa"
                    },
                    "deskripsi": {
                      "type": "string",
                      "example": "Menjelajahi kuliner laksa terbaik"
                    },
                    "image": {
                      "type": "string",
                      "format": "binary"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Rute thematic berhasil ditambahkan"
            }
          }
        }
      },
      "/api/thematic-routes/{id}": {
        "get": {
          "summary": "Mengambil detail rute thematic",
          "tags": [
            "Thematic Routes"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail rute thematic",
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "success": {
                        "type": "boolean"
                      },
                      "message": {
                        "type": "string"
                      },
                      "data": {
                        "type": "object",
                        "properties": {
                          "id": {
                            "type": "integer"
                          },
                          "judul_rute": {
                            "type": "string"
                          },
                          "deskripsi": {
                            "type": "string"
                          },
                          "image_url": {
                            "type": "string"
                          },
                          "is_delete": {
                            "type": "boolean"
                          },
                          "created_at": {
                            "type": "string"
                          },
                          "updated_at": {
                            "type": "string"
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "put": {
          "summary": "Mengubah rute thematic",
          "tags": [
            "Thematic Routes"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "judul_rute": {
                      "type": "string",
                      "example": "Wisata Laksa Update"
                    },
                    "deskripsi": {
                      "type": "string",
                      "example": "Deskripsi terbaru"
                    },
                    "image": {
                      "type": "string",
                      "format": "binary"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Rute thematic berhasil diupdate"
            }
          }
        },
        "delete": {
          "summary": "Soft delete rute thematic",
          "tags": [
            "Thematic Routes"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Rute thematic berhasil dihapus"
            }
          }
        }
      },
      "/api/thematic-routes/restore/{id}": {
        "put": {
          "summary": "Restore rute thematic",
          "tags": [
            "Thematic Routes"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Rute thematic berhasil direstore"
            }
          }
        }
      },
      "/api/route-details": {
        "post": {
          "summary": "Menambahkan route detail",
          "tags": [
            "Route Details"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "merchant_id",
                    "thematic_route_id"
                  ],
                  "properties": {
                    "merchant_id": {
                      "type": "integer",
                      "example": 1
                    },
                    "thematic_route_id": {
                      "type": "integer",
                      "example": 1
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Route detail berhasil ditambahkan"
            }
          }
        },
        "get": {
          "summary": "Mengambil semua route detail",
          "tags": [
            "Route Details"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil semua route detail"
            }
          }
        }
      },
      "/api/route-details/{id}": {
        "get": {
          "summary": "Mengambil detail route berdasarkan id",
          "tags": [
            "Route Details"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              },
              "description": "ID Route Detail"
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail route"
            }
          }
        },
        "delete": {
          "summary": "Menghapus route detail",
          "tags": [
            "Route Details"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              },
              "description": "ID Route Detail"
            }
          ],
          "responses": {
            "200": {
              "description": "Route detail berhasil dihapus"
            }
          }
        }
      },
      "/api/reviews": {
        "get": {
          "summary": "Mengambil semua review",
          "tags": [
            "Reviews"
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data review",
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "success": {
                        "type": "boolean"
                      },
                      "message": {
                        "type": "string"
                      },
                      "data": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "id": {
                              "type": "integer"
                            },
                            "customer_id": {
                              "type": "integer"
                            },
                            "rating": {
                              "type": "integer"
                            },
                            "deskripsi": {
                              "type": "string"
                            },
                            "image_url": {
                              "type": "string",
                              "nullable": true
                            },
                            "is_delete": {
                              "type": "boolean"
                            },
                            "submitted_at": {
                              "type": "string",
                              "format": "date-time"
                            },
                            "customer_name": {
                              "type": "string"
                            },
                            "nama_bisnis": {
                              "type": "string"
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "post": {
          "summary": "Membuat review merchant",
          "tags": [
            "Reviews"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "customer_id": {
                      "type": "integer"
                    },
                    "merchant_id": {
                      "type": "integer"
                    },
                    "rating": {
                      "type": "integer"
                    },
                    "deskripsi": {
                      "type": "string"
                    },
                    "image": {
                      "type": "string",
                      "format": "binary"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Review berhasil dibuat"
            }
          }
        }
      },
      "/api/reviews/{id}": {
        "get": {
          "summary": "Mengambil detail review",
          "tags": [
            "Reviews"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "description": "ID review",
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail review",
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "success": {
                        "type": "boolean"
                      },
                      "message": {
                        "type": "string"
                      },
                      "data": {
                        "type": "object",
                        "properties": {
                          "id": {
                            "type": "integer"
                          },
                          "customer_id": {
                            "type": "integer"
                          },
                          "rating": {
                            "type": "integer"
                          },
                          "deskripsi": {
                            "type": "string"
                          },
                          "image_url": {
                            "type": "string",
                            "nullable": true
                          },
                          "is_delete": {
                            "type": "boolean"
                          },
                          "submitted_at": {
                            "type": "string",
                            "format": "date-time"
                          },
                          "customer_name": {
                            "type": "string"
                          },
                          "nama_bisnis": {
                            "type": "string"
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            "404": {
              "description": "Review tidak ditemukan"
            }
          }
        },
        "delete": {
          "summary": "Soft delete review",
          "tags": [
            "Reviews"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Review berhasil dihapus"
            }
          }
        }
      },
      "/api/reviews/restore/{id}": {
        "put": {
          "summary": "Memulihkan review",
          "tags": [
            "Reviews"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Review berhasil dipulihkan"
            }
          }
        }
      },
      "/api/promotions": {
        "get": {
          "summary": "Mengambil semua promo",
          "tags": [
            "Promotions"
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data promo"
            }
          }
        },
        "post": {
          "summary": "Menambahkan promo produk",
          "tags": [
            "Promotions"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "product_id": {
                      "type": "integer"
                    },
                    "tipe_promo": {
                      "type": "string"
                    },
                    "diskon": {
                      "type": "integer"
                    },
                    "kuota": {
                      "type": "integer"
                    },
                    "tanggal_berlaku": {
                      "type": "string"
                    },
                    "tanggal_expired": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Promo berhasil ditambahkan"
            }
          }
        }
      },
      "/api/promotions/{id}": {
        "get": {
          "summary": "Mengambil detail promo",
          "tags": [
            "Promotions"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail promo"
            }
          }
        },
        "put": {
          "summary": "Mengubah promo",
          "tags": [
            "Promotions"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "tipe_promo": {
                      "type": "string"
                    },
                    "diskon": {
                      "type": "integer"
                    },
                    "kuota": {
                      "type": "integer"
                    },
                    "tanggal_berlaku": {
                      "type": "string"
                    },
                    "tanggal_expired": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Promo berhasil diupdate"
            }
          }
        },
        "delete": {
          "summary": "Soft delete promo",
          "tags": [
            "Promotions"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Promo berhasil dihapus"
            }
          }
        }
      },
      "/api/promotions/product/{productId}": {
        "get": {
          "summary": "Mengambil promo berdasarkan produk",
          "tags": [
            "Promotions"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "productId",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil promo produk"
            }
          }
        }
      },
      "/api/products": {
        "get": {
          "summary": "Mengambil semua produk",
          "tags": [
            "Products"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data produk"
            }
          }
        },
        "post": {
          "summary": "Menambahkan produk merchant",
          "tags": [
            "Products"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "required": [
                    "merchant_id",
                    "category_id",
                    "nama_produk",
                    "harga_produk"
                  ],
                  "properties": {
                    "merchant_id": {
                      "type": "integer",
                      "example": 1
                    },
                    "category_id": {
                      "type": "integer",
                      "example": 1
                    },
                    "nama_produk": {
                      "type": "string",
                      "example": "Nasi Goreng Spesial"
                    },
                    "harga_produk": {
                      "type": "integer",
                      "example": 25000
                    },
                    "deskripsi": {
                      "type": "string",
                      "example": "Nasi goreng dengan telur dan ayam"
                    },
                    "image": {
                      "type": "string",
                      "format": "binary"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Produk berhasil ditambahkan"
            }
          }
        }
      },
      "/api/products/{id}": {
        "get": {
          "summary": "Mengambil detail produk",
          "tags": [
            "Products"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail produk"
            }
          }
        },
        "put": {
          "summary": "Mengubah produk",
          "tags": [
            "Products"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "required": [
                    "category_id",
                    "nama_produk",
                    "harga_produk",
                    "is_available"
                  ],
                  "properties": {
                    "category_id": {
                      "type": "integer",
                      "example": 1
                    },
                    "nama_produk": {
                      "type": "string",
                      "example": "Nasi Goreng Spesial"
                    },
                    "harga_produk": {
                      "type": "integer",
                      "example": 25000
                    },
                    "deskripsi": {
                      "type": "string",
                      "example": "Nasi goreng dengan telur dan ayam"
                    },
                    "is_available": {
                      "type": "boolean",
                      "example": true
                    },
                    "image": {
                      "type": "string",
                      "format": "binary"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Produk berhasil diupdate"
            }
          }
        }
      },
      "/api/merchants": {
        "get": {
          "summary": "Mengambil semua merchant",
          "tags": [
            "Merchants"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil semua merchant"
            }
          }
        }
      },
      "/api/merchants/{id}": {
        "get": {
          "summary": "Mengambil detail merchant berdasarkan id",
          "tags": [
            "Merchants"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail merchant"
            }
          }
        }
      },
      "/api/merchants/user/{user_id}": {
        "get": {
          "summary": "Mengambil merchant berdasarkan user id",
          "tags": [
            "Merchants"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "user_id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data merchant"
            }
          }
        }
      },
      "/api/merchants/{id}/information": {
        "put": {
          "summary": "Update informasi bisnis merchant",
          "tags": [
            "Merchants"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              },
              "description": "ID merchant"
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "multipart/form-data": {
                "schema": {
                  "type": "object",
                  "required": [
                    "nama_bisnis",
                    "usaha_didirikan",
                    "jam_buka",
                    "jam_tutup",
                    "deskripsi"
                  ],
                  "properties": {
                    "nama_bisnis": {
                      "type": "string",
                      "example": "Kedai Kopi Litera"
                    },
                    "usaha_didirikan": {
                      "type": "string",
                      "format": "date",
                      "example": "2023-10-19"
                    },
                    "jam_buka": {
                      "type": "string",
                      "example": "08:00"
                    },
                    "jam_tutup": {
                      "type": "string",
                      "example": "22:00"
                    },
                    "deskripsi": {
                      "type": "string",
                      "example": "Tempat nongkrong nyaman dan menyediakan kopi lokal."
                    },
                    "image_url": {
                      "type": "string",
                      "format": "binary",
                      "description": "Foto utama merchant"
                    },
                    "image_qr": {
                      "type": "string",
                      "format": "binary",
                      "description": "QRIS merchant"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Informasi bisnis berhasil diperbarui"
            },
            "400": {
              "description": "Validasi gagal"
            },
            "404": {
              "description": "Merchant tidak ditemukan"
            }
          }
        }
      },
      "/api/merchants/{id}/status": {
        "put": {
          "summary": "Update status merchant",
          "tags": [
            "Merchants"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              },
              "description": "ID merchant"
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "status"
                  ],
                  "properties": {
                    "status": {
                      "type": "string",
                      "enum": [
                        "Buka",
                        "Tutup"
                      ],
                      "example": "Buka"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Status merchant berhasil diperbarui"
            },
            "400": {
              "description": "Status tidak valid"
            },
            "404": {
              "description": "Merchant tidak ditemukan"
            }
          }
        }
      },
      "/api/merchant-locations": {
        "get": {
          "summary": "Mengambil semua lokasi merchant",
          "tags": [
            "Merchant Locations"
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil data lokasi merchant"
            }
          }
        },
        "post": {
          "summary": "Menambahkan lokasi merchant",
          "tags": [
            "Merchant Locations"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "merchant_id": {
                      "type": "integer"
                    },
                    "latitude": {
                      "type": "number"
                    },
                    "longitude": {
                      "type": "number"
                    },
                    "alamat": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Lokasi merchant berhasil ditambahkan"
            }
          }
        }
      },
      "/api/merchant-locations/{id}": {
        "get": {
          "summary": "Mengambil detail lokasi merchant",
          "tags": [
            "Merchant Locations"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail lokasi merchant"
            }
          }
        },
        "put": {
          "summary": "Mengubah lokasi merchant",
          "tags": [
            "Merchant Locations"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "latitude": {
                      "type": "number"
                    },
                    "longitude": {
                      "type": "number"
                    },
                    "alamat": {
                      "type": "string"
                    },
                    "is_active": {
                      "type": "boolean"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Lokasi merchant berhasil diupdate"
            }
          }
        }
      },
      "/api/customer-vouchers/customer/{customerId}": {
        "get": {
          "summary": "Mengambil voucher customer",
          "tags": [
            "Customer Vouchers"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "customerId",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil voucher customer"
            }
          }
        }
      },
      "/api/customer-vouchers": {
        "post": {
          "summary": "Claim voucher promo",
          "tags": [
            "Customer Vouchers"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "customer_id": {
                      "type": "integer"
                    },
                    "promotion_id": {
                      "type": "integer"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Voucher berhasil diklaim"
            }
          }
        }
      },
      "/api/customer-vouchers/cancel/{id}": {
        "put": {
          "summary": "Membatalkan voucher customer",
          "tags": [
            "Customer Vouchers"
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Voucher berhasil dibatalkan"
            }
          }
        }
      },
      "/api/customers": {
        "get": {
          "summary": "Mengambil semua customer",
          "tags": [
            "Customers"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil semua customer"
            }
          }
        }
      },
      "/api/customers/{id}": {
        "get": {
          "summary": "Mengambil detail customer berdasarkan id",
          "tags": [
            "Customers"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail customer"
            }
          }
        }
      },
      "/api/category-products": {
        "get": {
          "summary": "Mengambil semua kategori produk",
          "tags": [
            "Category Products"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil semua kategori produk"
            }
          }
        }
      },
      "/api/category-products/{id}": {
        "get": {
          "summary": "Mengambil detail kategori produk",
          "tags": [
            "Category Products"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "Berhasil mengambil detail kategori produk"
            }
          }
        }
      },
      "/api/auth/register": {
        "post": {
          "summary": "Register user baru",
          "tags": [
            "Auth"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "username": {
                      "type": "string"
                    },
                    "name": {
                      "type": "string"
                    },
                    "email": {
                      "type": "string"
                    },
                    "password": {
                      "type": "string"
                    },
                    "role": {
                      "type": "integer"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Register berhasil"
            }
          }
        }
      },
      "/api/auth/login": {
        "post": {
          "summary": "Login user",
          "tags": [
            "Auth"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "username": {
                      "type": "string"
                    },
                    "password": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Login berhasil"
            }
          }
        }
      },
      "/api/auth/send-reset-otp": {
        "post": {
          "summary": "Mengirim OTP reset password ke email",
          "tags": [
            "Auth"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "email"
                  ],
                  "properties": {
                    "email": {
                      "type": "string",
                      "example": "user@gmail.com"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "OTP berhasil dikirim ke email"
            },
            "400": {
              "description": "Email tidak ditemukan"
            }
          }
        }
      },
      "/api/auth/reset-password": {
        "post": {
          "summary": "Reset password menggunakan OTP",
          "tags": [
            "Auth"
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "email",
                    "otp",
                    "new_password"
                  ],
                  "properties": {
                    "email": {
                      "type": "string",
                      "example": "user@gmail.com"
                    },
                    "otp": {
                      "type": "string",
                      "example": "123456"
                    },
                    "new_password": {
                      "type": "string",
                      "example": "passwordBaru123"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Password berhasil direset"
            },
            "400": {
              "description": "OTP salah atau expired"
            }
          }
        }
      },
      "/api/auth/change-password": {
        "put": {
          "summary": "Mengubah password user yang sedang login",
          "tags": [
            "Auth"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "old_password",
                    "new_password"
                  ],
                  "properties": {
                    "old_password": {
                      "type": "string",
                      "example": "passwordLama123"
                    },
                    "new_password": {
                      "type": "string",
                      "example": "passwordBaru123"
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Password berhasil diubah"
            }
          }
        }
      },
      "/api/auth/biometric/{id}": {
        "put": {
          "summary": "Mengubah status biometrik user",
          "tags": [
            "Auth"
          ],
          "security": [
            {
              "bearerAuth": []
            }
          ],
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "requestBody": {
            "required": true,
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "required": [
                    "biometric_enabled"
                  ],
                  "properties": {
                    "biometric_enabled": {
                      "type": "boolean",
                      "example": true
                    }
                  }
                }
              }
            }
          },
          "responses": {
            "200": {
              "description": "Status biometrik berhasil diperbarui"
            }
          }
        }
      }
    },
    "tags": []
  },
  "customOptions": {}
};
  url = options.swaggerUrl || url
  var urls = options.swaggerUrls
  var customOptions = options.customOptions
  var spec1 = options.swaggerDoc
  var swaggerOptions = {
    spec: spec1,
    url: url,
    urls: urls,
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
      SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "StandaloneLayout"
  }
  for (var attrname in customOptions) {
    swaggerOptions[attrname] = customOptions[attrname];
  }
  var ui = SwaggerUIBundle(swaggerOptions)

  if (customOptions.oauth) {
    ui.initOAuth(customOptions.oauth)
  }

  if (customOptions.preauthorizeApiKey) {
    const key = customOptions.preauthorizeApiKey.authDefinitionKey;
    const value = customOptions.preauthorizeApiKey.apiKeyValue;
    if (!!key && !!value) {
      const pid = setInterval(() => {
        const authorized = ui.preauthorizeApiKey(key, value);
        if(!!authorized) clearInterval(pid);
      }, 500)

    }
  }

  if (customOptions.authAction) {
    ui.authActions.authorize(customOptions.authAction)
  }

  window.ui = ui
}

