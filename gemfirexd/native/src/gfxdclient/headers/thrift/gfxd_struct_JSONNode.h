/**
 * Autogenerated by Thrift Compiler (0.9.1)
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 *  @generated
 */

/*
 * Changes for GemFireXD distributed data platform.
 *
 * Portions Copyright (c) 2010-2015 Pivotal Software, Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License. You
 * may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License. See accompanying
 * LICENSE file.
 */

#ifndef GFXD_STRUCT_JSONNODE_H
#define GFXD_STRUCT_JSONNODE_H


#include "gfxd_types.h"

#include "gfxd_struct_FieldDescriptor.h"
#include "gfxd_struct_Decimal.h"
#include "gfxd_struct_Timestamp.h"
#include "gfxd_struct_FieldValue.h"
#include "gfxd_struct_PDXNode.h"
#include "gfxd_struct_PDXObject.h"
#include "gfxd_struct_PDXSchemaNode.h"
#include "gfxd_struct_PDXSchema.h"
#include "gfxd_struct_JSONField.h"

namespace com { namespace pivotal { namespace gemfirexd { namespace thrift {

typedef struct _JSONNode__isset {
  _JSONNode__isset() : pairs(false), singleField(false) {}
  bool pairs;
  bool singleField;
} _JSONNode__isset;

class JSONNode {
 public:

  static const char* ascii_fingerprint; // = "5A95EABAC69D86B566979162EB10A2FE";
  static const uint8_t binary_fingerprint[16]; // = {0x5A,0x95,0xEA,0xBA,0xC6,0x9D,0x86,0xB5,0x66,0x97,0x91,0x62,0xEB,0x10,0xA2,0xFE};

  JSONNode() : refId(0) {
  }

#if __cplusplus >= 201103L
  JSONNode(const JSONNode& other) = default;
  JSONNode& operator=(const JSONNode& other) = default;

  JSONNode(JSONNode&& other) :
      pairs(std::move(other.pairs)), singleField(std::move(other.singleField)),
      refId(other.refId), __isset(other.__isset) {
  }

  void assign(JSONNode&& other) {
    pairs.operator =(std::move(other.pairs));
    singleField.assign(std::move(other.singleField));
    refId = other.refId;
    __isset = other.__isset;
  }

  JSONNode& operator=(JSONNode&& other) {
    assign(std::move(other));
    return *this;
  }
#endif
 
  virtual ~JSONNode() throw() {}

  std::map<std::string, JSONField>  pairs;
  JSONField singleField;
  int32_t refId;

  _JSONNode__isset __isset;

  void __set_pairs(const std::map<std::string, JSONField> & val) {
    pairs = val;
    __isset.pairs = true;
  }

  void __set_singleField(const JSONField& val) {
    singleField = val;
    __isset.singleField = true;
  }

  void __set_refId(const int32_t val) {
    refId = val;
  }

  bool operator == (const JSONNode & rhs) const
  {
    if (__isset.pairs != rhs.__isset.pairs)
      return false;
    else if (__isset.pairs && !(pairs == rhs.pairs))
      return false;
    if (__isset.singleField != rhs.__isset.singleField)
      return false;
    else if (__isset.singleField && !(singleField == rhs.singleField))
      return false;
    if (!(refId == rhs.refId))
      return false;
    return true;
  }
  bool operator != (const JSONNode &rhs) const {
    return !(*this == rhs);
  }

  bool operator < (const JSONNode & ) const;

  uint32_t read(::apache::thrift::protocol::TProtocol* iprot);
  uint32_t write(::apache::thrift::protocol::TProtocol* oprot) const;

};

void swap(JSONNode &a, JSONNode &b);

}}}} // namespace

#endif
