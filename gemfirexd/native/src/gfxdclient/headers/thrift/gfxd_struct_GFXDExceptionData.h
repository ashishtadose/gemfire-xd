/**
 * Autogenerated by Thrift Compiler (0.9.1)
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 *  @generated
 */

#ifndef GFXD_STRUCT_GFXDEXCEPTIONDATA_H
#define GFXD_STRUCT_GFXDEXCEPTIONDATA_H


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
#include "gfxd_struct_JSONNode.h"
#include "gfxd_struct_JSONObject.h"
#include "gfxd_struct_BlobChunk.h"
#include "gfxd_struct_ClobChunk.h"
#include "gfxd_struct_ServiceMetaData.h"
#include "gfxd_struct_ServiceMetaDataArgs.h"
#include "gfxd_struct_OpenConnectionArgs.h"
#include "gfxd_struct_ConnectionProperties.h"
#include "gfxd_struct_HostAddress.h"

namespace com { namespace pivotal { namespace gemfirexd { namespace thrift {


class GFXDExceptionData {
 public:

  static const char* ascii_fingerprint; // = "343DA57F446177400B333DC49B037B0C";
  static const uint8_t binary_fingerprint[16]; // = {0x34,0x3D,0xA5,0x7F,0x44,0x61,0x77,0x40,0x0B,0x33,0x3D,0xC4,0x9B,0x03,0x7B,0x0C};

  GFXDExceptionData() : reason(), sqlState(), severity(0) {
  }

  virtual ~GFXDExceptionData() throw() {}

  std::string reason;
  std::string sqlState;
  int32_t severity;

  void __set_reason(const std::string& val) {
    reason = val;
  }

  void __set_sqlState(const std::string& val) {
    sqlState = val;
  }

  void __set_severity(const int32_t val) {
    severity = val;
  }

  bool operator == (const GFXDExceptionData & rhs) const
  {
    if (!(reason == rhs.reason))
      return false;
    if (!(sqlState == rhs.sqlState))
      return false;
    if (!(severity == rhs.severity))
      return false;
    return true;
  }
  bool operator != (const GFXDExceptionData &rhs) const {
    return !(*this == rhs);
  }

  bool operator < (const GFXDExceptionData & ) const;

  uint32_t read(::apache::thrift::protocol::TProtocol* iprot);
  uint32_t write(::apache::thrift::protocol::TProtocol* oprot) const;

};

void swap(GFXDExceptionData &a, GFXDExceptionData &b);

}}}} // namespace

#endif
