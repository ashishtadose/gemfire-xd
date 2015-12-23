/**
 * Autogenerated by Thrift Compiler (0.9.1)
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 *  @generated
 */

package com.pivotal.gemfirexd.thrift;

import org.apache.thrift.scheme.IScheme;
import org.apache.thrift.scheme.SchemeFactory;
import org.apache.thrift.scheme.StandardScheme;

import org.apache.thrift.scheme.TupleScheme;
import org.apache.thrift.protocol.TTupleProtocol;
import org.apache.thrift.protocol.TProtocolException;
import org.apache.thrift.EncodingUtils;
import org.apache.thrift.TException;
import org.apache.thrift.async.AsyncMethodCallback;
import org.apache.thrift.server.AbstractNonblockingServer.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.EnumMap;
import java.util.Set;
import java.util.HashSet;
import java.util.EnumSet;
import java.util.Collections;
import java.util.BitSet;
import java.nio.ByteBuffer;
import java.util.Arrays;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ColumnDescriptor implements org.apache.thrift.TBase<ColumnDescriptor, ColumnDescriptor._Fields>, java.io.Serializable, Comparable<ColumnDescriptor> {
  private static final org.apache.thrift.protocol.TStruct STRUCT_DESC = new org.apache.thrift.protocol.TStruct("ColumnDescriptor");

  private static final org.apache.thrift.protocol.TField TYPE_FIELD_DESC = new org.apache.thrift.protocol.TField("type", org.apache.thrift.protocol.TType.I32, (short)1);
  private static final org.apache.thrift.protocol.TField DESC_FLAGS_FIELD_DESC = new org.apache.thrift.protocol.TField("descFlags", org.apache.thrift.protocol.TType.I16, (short)2);
  private static final org.apache.thrift.protocol.TField PRECISION_FIELD_DESC = new org.apache.thrift.protocol.TField("precision", org.apache.thrift.protocol.TType.I16, (short)3);
  private static final org.apache.thrift.protocol.TField SCALE_FIELD_DESC = new org.apache.thrift.protocol.TField("scale", org.apache.thrift.protocol.TType.I16, (short)4);
  private static final org.apache.thrift.protocol.TField NAME_FIELD_DESC = new org.apache.thrift.protocol.TField("name", org.apache.thrift.protocol.TType.STRING, (short)5);
  private static final org.apache.thrift.protocol.TField FULL_TABLE_NAME_FIELD_DESC = new org.apache.thrift.protocol.TField("fullTableName", org.apache.thrift.protocol.TType.STRING, (short)6);
  private static final org.apache.thrift.protocol.TField UDT_TYPE_AND_CLASS_NAME_FIELD_DESC = new org.apache.thrift.protocol.TField("udtTypeAndClassName", org.apache.thrift.protocol.TType.STRING, (short)7);

  private static final Map<Class<? extends IScheme>, SchemeFactory> schemes = new HashMap<Class<? extends IScheme>, SchemeFactory>();
  static {
    schemes.put(StandardScheme.class, new ColumnDescriptorStandardSchemeFactory());
    schemes.put(TupleScheme.class, new ColumnDescriptorTupleSchemeFactory());
  }

  /**
   * 
   * @see GFXDType
   */
  public GFXDType type; // required
  public short descFlags; // required
  public short precision; // required
  public short scale; // optional
  public String name; // optional
  public String fullTableName; // optional
  public String udtTypeAndClassName; // optional

  /** The set of fields this struct contains, along with convenience methods for finding and manipulating them. */
  public enum _Fields implements org.apache.thrift.TFieldIdEnum {
    /**
     * 
     * @see GFXDType
     */
    TYPE((short)1, "type"),
    DESC_FLAGS((short)2, "descFlags"),
    PRECISION((short)3, "precision"),
    SCALE((short)4, "scale"),
    NAME((short)5, "name"),
    FULL_TABLE_NAME((short)6, "fullTableName"),
    UDT_TYPE_AND_CLASS_NAME((short)7, "udtTypeAndClassName");

    private static final Map<String, _Fields> byName = new HashMap<String, _Fields>();

    static {
      for (_Fields field : EnumSet.allOf(_Fields.class)) {
        byName.put(field.getFieldName(), field);
      }
    }

    /**
     * Find the _Fields constant that matches fieldId, or null if its not found.
     */
    public static _Fields findByThriftId(int fieldId) {
      switch(fieldId) {
        case 1: // TYPE
          return TYPE;
        case 2: // DESC_FLAGS
          return DESC_FLAGS;
        case 3: // PRECISION
          return PRECISION;
        case 4: // SCALE
          return SCALE;
        case 5: // NAME
          return NAME;
        case 6: // FULL_TABLE_NAME
          return FULL_TABLE_NAME;
        case 7: // UDT_TYPE_AND_CLASS_NAME
          return UDT_TYPE_AND_CLASS_NAME;
        default:
          return null;
      }
    }

    /**
     * Find the _Fields constant that matches fieldId, throwing an exception
     * if it is not found.
     */
    public static _Fields findByThriftIdOrThrow(int fieldId) {
      _Fields fields = findByThriftId(fieldId);
      if (fields == null) throw new IllegalArgumentException("Field " + fieldId + " doesn't exist!");
      return fields;
    }

    /**
     * Find the _Fields constant that matches name, or null if its not found.
     */
    public static _Fields findByName(String name) {
      return byName.get(name);
    }

    private final short _thriftId;
    private final String _fieldName;

    _Fields(short thriftId, String fieldName) {
      _thriftId = thriftId;
      _fieldName = fieldName;
    }

    public short getThriftFieldId() {
      return _thriftId;
    }

    public String getFieldName() {
      return _fieldName;
    }
  }

  // isset id assignments
  private static final int __DESCFLAGS_ISSET_ID = 0;
  private static final int __PRECISION_ISSET_ID = 1;
  private static final int __SCALE_ISSET_ID = 2;
  private byte __isset_bitfield = 0;
  private _Fields optionals[] = {_Fields.SCALE,_Fields.NAME,_Fields.FULL_TABLE_NAME,_Fields.UDT_TYPE_AND_CLASS_NAME};
  public static final Map<_Fields, org.apache.thrift.meta_data.FieldMetaData> metaDataMap;
  static {
    Map<_Fields, org.apache.thrift.meta_data.FieldMetaData> tmpMap = new EnumMap<_Fields, org.apache.thrift.meta_data.FieldMetaData>(_Fields.class);
    tmpMap.put(_Fields.TYPE, new org.apache.thrift.meta_data.FieldMetaData("type", org.apache.thrift.TFieldRequirementType.REQUIRED, 
        new org.apache.thrift.meta_data.EnumMetaData(org.apache.thrift.protocol.TType.ENUM, GFXDType.class)));
    tmpMap.put(_Fields.DESC_FLAGS, new org.apache.thrift.meta_data.FieldMetaData("descFlags", org.apache.thrift.TFieldRequirementType.REQUIRED, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.I16)));
    tmpMap.put(_Fields.PRECISION, new org.apache.thrift.meta_data.FieldMetaData("precision", org.apache.thrift.TFieldRequirementType.REQUIRED, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.I16)));
    tmpMap.put(_Fields.SCALE, new org.apache.thrift.meta_data.FieldMetaData("scale", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.I16)));
    tmpMap.put(_Fields.NAME, new org.apache.thrift.meta_data.FieldMetaData("name", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.STRING)));
    tmpMap.put(_Fields.FULL_TABLE_NAME, new org.apache.thrift.meta_data.FieldMetaData("fullTableName", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.STRING)));
    tmpMap.put(_Fields.UDT_TYPE_AND_CLASS_NAME, new org.apache.thrift.meta_data.FieldMetaData("udtTypeAndClassName", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.STRING)));
    metaDataMap = Collections.unmodifiableMap(tmpMap);
    org.apache.thrift.meta_data.FieldMetaData.addStructMetaDataMap(ColumnDescriptor.class, metaDataMap);
  }

  public ColumnDescriptor() {
  }

  public ColumnDescriptor(
    GFXDType type,
    short descFlags,
    short precision)
  {
    this();
    this.type = type;
    this.descFlags = descFlags;
    setDescFlagsIsSet(true);
    this.precision = precision;
    setPrecisionIsSet(true);
  }

  /**
   * Performs a deep copy on <i>other</i>.
   */
  public ColumnDescriptor(ColumnDescriptor other) {
    __isset_bitfield = other.__isset_bitfield;
    if (other.isSetType()) {
      this.type = other.type;
    }
    this.descFlags = other.descFlags;
    this.precision = other.precision;
    this.scale = other.scale;
    if (other.isSetName()) {
      this.name = other.name;
    }
    if (other.isSetFullTableName()) {
      this.fullTableName = other.fullTableName;
    }
    if (other.isSetUdtTypeAndClassName()) {
      this.udtTypeAndClassName = other.udtTypeAndClassName;
    }
  }

  public ColumnDescriptor deepCopy() {
    return new ColumnDescriptor(this);
  }

  @Override
  public void clear() {
    this.type = null;
    setDescFlagsIsSet(false);
    this.descFlags = 0;
    setPrecisionIsSet(false);
    this.precision = 0;
    setScaleIsSet(false);
    this.scale = 0;
    this.name = null;
    this.fullTableName = null;
    this.udtTypeAndClassName = null;
  }

  /**
   * 
   * @see GFXDType
   */
  public GFXDType getType() {
    return this.type;
  }

  /**
   * 
   * @see GFXDType
   */
  public ColumnDescriptor setType(GFXDType type) {
    this.type = type;
    return this;
  }

  public void unsetType() {
    this.type = null;
  }

  /** Returns true if field type is set (has been assigned a value) and false otherwise */
  public boolean isSetType() {
    return this.type != null;
  }

  public void setTypeIsSet(boolean value) {
    if (!value) {
      this.type = null;
    }
  }

  public short getDescFlags() {
    return this.descFlags;
  }

  public ColumnDescriptor setDescFlags(short descFlags) {
    this.descFlags = descFlags;
    setDescFlagsIsSet(true);
    return this;
  }

  public void unsetDescFlags() {
    __isset_bitfield = EncodingUtils.clearBit(__isset_bitfield, __DESCFLAGS_ISSET_ID);
  }

  /** Returns true if field descFlags is set (has been assigned a value) and false otherwise */
  public boolean isSetDescFlags() {
    return EncodingUtils.testBit(__isset_bitfield, __DESCFLAGS_ISSET_ID);
  }

  public void setDescFlagsIsSet(boolean value) {
    __isset_bitfield = EncodingUtils.setBit(__isset_bitfield, __DESCFLAGS_ISSET_ID, value);
  }

  public short getPrecision() {
    return this.precision;
  }

  public ColumnDescriptor setPrecision(short precision) {
    this.precision = precision;
    setPrecisionIsSet(true);
    return this;
  }

  public void unsetPrecision() {
    __isset_bitfield = EncodingUtils.clearBit(__isset_bitfield, __PRECISION_ISSET_ID);
  }

  /** Returns true if field precision is set (has been assigned a value) and false otherwise */
  public boolean isSetPrecision() {
    return EncodingUtils.testBit(__isset_bitfield, __PRECISION_ISSET_ID);
  }

  public void setPrecisionIsSet(boolean value) {
    __isset_bitfield = EncodingUtils.setBit(__isset_bitfield, __PRECISION_ISSET_ID, value);
  }

  public short getScale() {
    return this.scale;
  }

  public ColumnDescriptor setScale(short scale) {
    this.scale = scale;
    setScaleIsSet(true);
    return this;
  }

  public void unsetScale() {
    __isset_bitfield = EncodingUtils.clearBit(__isset_bitfield, __SCALE_ISSET_ID);
  }

  /** Returns true if field scale is set (has been assigned a value) and false otherwise */
  public boolean isSetScale() {
    return EncodingUtils.testBit(__isset_bitfield, __SCALE_ISSET_ID);
  }

  public void setScaleIsSet(boolean value) {
    __isset_bitfield = EncodingUtils.setBit(__isset_bitfield, __SCALE_ISSET_ID, value);
  }

  public String getName() {
    return this.name;
  }

  public ColumnDescriptor setName(String name) {
    this.name = name;
    return this;
  }

  public void unsetName() {
    this.name = null;
  }

  /** Returns true if field name is set (has been assigned a value) and false otherwise */
  public boolean isSetName() {
    return this.name != null;
  }

  public void setNameIsSet(boolean value) {
    if (!value) {
      this.name = null;
    }
  }

  public String getFullTableName() {
    return this.fullTableName;
  }

  public ColumnDescriptor setFullTableName(String fullTableName) {
    this.fullTableName = fullTableName;
    return this;
  }

  public void unsetFullTableName() {
    this.fullTableName = null;
  }

  /** Returns true if field fullTableName is set (has been assigned a value) and false otherwise */
  public boolean isSetFullTableName() {
    return this.fullTableName != null;
  }

  public void setFullTableNameIsSet(boolean value) {
    if (!value) {
      this.fullTableName = null;
    }
  }

  public String getUdtTypeAndClassName() {
    return this.udtTypeAndClassName;
  }

  public ColumnDescriptor setUdtTypeAndClassName(String udtTypeAndClassName) {
    this.udtTypeAndClassName = udtTypeAndClassName;
    return this;
  }

  public void unsetUdtTypeAndClassName() {
    this.udtTypeAndClassName = null;
  }

  /** Returns true if field udtTypeAndClassName is set (has been assigned a value) and false otherwise */
  public boolean isSetUdtTypeAndClassName() {
    return this.udtTypeAndClassName != null;
  }

  public void setUdtTypeAndClassNameIsSet(boolean value) {
    if (!value) {
      this.udtTypeAndClassName = null;
    }
  }

  public void setFieldValue(_Fields field, Object value) {
    switch (field) {
    case TYPE:
      if (value == null) {
        unsetType();
      } else {
        setType((GFXDType)value);
      }
      break;

    case DESC_FLAGS:
      if (value == null) {
        unsetDescFlags();
      } else {
        setDescFlags((Short)value);
      }
      break;

    case PRECISION:
      if (value == null) {
        unsetPrecision();
      } else {
        setPrecision((Short)value);
      }
      break;

    case SCALE:
      if (value == null) {
        unsetScale();
      } else {
        setScale((Short)value);
      }
      break;

    case NAME:
      if (value == null) {
        unsetName();
      } else {
        setName((String)value);
      }
      break;

    case FULL_TABLE_NAME:
      if (value == null) {
        unsetFullTableName();
      } else {
        setFullTableName((String)value);
      }
      break;

    case UDT_TYPE_AND_CLASS_NAME:
      if (value == null) {
        unsetUdtTypeAndClassName();
      } else {
        setUdtTypeAndClassName((String)value);
      }
      break;

    }
  }

  public Object getFieldValue(_Fields field) {
    switch (field) {
    case TYPE:
      return getType();

    case DESC_FLAGS:
      return Short.valueOf(getDescFlags());

    case PRECISION:
      return Short.valueOf(getPrecision());

    case SCALE:
      return Short.valueOf(getScale());

    case NAME:
      return getName();

    case FULL_TABLE_NAME:
      return getFullTableName();

    case UDT_TYPE_AND_CLASS_NAME:
      return getUdtTypeAndClassName();

    }
    throw new IllegalStateException();
  }

  /** Returns true if field corresponding to fieldID is set (has been assigned a value) and false otherwise */
  public boolean isSet(_Fields field) {
    if (field == null) {
      throw new IllegalArgumentException();
    }

    switch (field) {
    case TYPE:
      return isSetType();
    case DESC_FLAGS:
      return isSetDescFlags();
    case PRECISION:
      return isSetPrecision();
    case SCALE:
      return isSetScale();
    case NAME:
      return isSetName();
    case FULL_TABLE_NAME:
      return isSetFullTableName();
    case UDT_TYPE_AND_CLASS_NAME:
      return isSetUdtTypeAndClassName();
    }
    throw new IllegalStateException();
  }

  @Override
  public boolean equals(Object that) {
    if (that == null)
      return false;
    if (that instanceof ColumnDescriptor)
      return this.equals((ColumnDescriptor)that);
    return false;
  }

  public boolean equals(ColumnDescriptor that) {
    if (that == null)
      return false;

    boolean this_present_type = true && this.isSetType();
    boolean that_present_type = true && that.isSetType();
    if (this_present_type || that_present_type) {
      if (!(this_present_type && that_present_type))
        return false;
      if (!this.type.equals(that.type))
        return false;
    }

    boolean this_present_descFlags = true;
    boolean that_present_descFlags = true;
    if (this_present_descFlags || that_present_descFlags) {
      if (!(this_present_descFlags && that_present_descFlags))
        return false;
      if (this.descFlags != that.descFlags)
        return false;
    }

    boolean this_present_precision = true;
    boolean that_present_precision = true;
    if (this_present_precision || that_present_precision) {
      if (!(this_present_precision && that_present_precision))
        return false;
      if (this.precision != that.precision)
        return false;
    }

    boolean this_present_scale = true && this.isSetScale();
    boolean that_present_scale = true && that.isSetScale();
    if (this_present_scale || that_present_scale) {
      if (!(this_present_scale && that_present_scale))
        return false;
      if (this.scale != that.scale)
        return false;
    }

    boolean this_present_name = true && this.isSetName();
    boolean that_present_name = true && that.isSetName();
    if (this_present_name || that_present_name) {
      if (!(this_present_name && that_present_name))
        return false;
      if (!this.name.equals(that.name))
        return false;
    }

    boolean this_present_fullTableName = true && this.isSetFullTableName();
    boolean that_present_fullTableName = true && that.isSetFullTableName();
    if (this_present_fullTableName || that_present_fullTableName) {
      if (!(this_present_fullTableName && that_present_fullTableName))
        return false;
      if (!this.fullTableName.equals(that.fullTableName))
        return false;
    }

    boolean this_present_udtTypeAndClassName = true && this.isSetUdtTypeAndClassName();
    boolean that_present_udtTypeAndClassName = true && that.isSetUdtTypeAndClassName();
    if (this_present_udtTypeAndClassName || that_present_udtTypeAndClassName) {
      if (!(this_present_udtTypeAndClassName && that_present_udtTypeAndClassName))
        return false;
      if (!this.udtTypeAndClassName.equals(that.udtTypeAndClassName))
        return false;
    }

    return true;
  }

  @Override
  public int hashCode() {
    return 0;
  }

  @Override
  public int compareTo(ColumnDescriptor other) {
    if (!getClass().equals(other.getClass())) {
      return getClass().getName().compareTo(other.getClass().getName());
    }

    int lastComparison = 0;

    lastComparison = Boolean.valueOf(isSetType()).compareTo(other.isSetType());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetType()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.type, other.type);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetDescFlags()).compareTo(other.isSetDescFlags());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetDescFlags()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.descFlags, other.descFlags);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetPrecision()).compareTo(other.isSetPrecision());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetPrecision()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.precision, other.precision);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetScale()).compareTo(other.isSetScale());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetScale()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.scale, other.scale);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetName()).compareTo(other.isSetName());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetName()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.name, other.name);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetFullTableName()).compareTo(other.isSetFullTableName());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetFullTableName()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.fullTableName, other.fullTableName);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetUdtTypeAndClassName()).compareTo(other.isSetUdtTypeAndClassName());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetUdtTypeAndClassName()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.udtTypeAndClassName, other.udtTypeAndClassName);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    return 0;
  }

  public _Fields fieldForId(int fieldId) {
    return _Fields.findByThriftId(fieldId);
  }

  public void read(org.apache.thrift.protocol.TProtocol iprot) throws org.apache.thrift.TException {
    schemes.get(iprot.getScheme()).getScheme().read(iprot, this);
  }

  public void write(org.apache.thrift.protocol.TProtocol oprot) throws org.apache.thrift.TException {
    schemes.get(oprot.getScheme()).getScheme().write(oprot, this);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder("ColumnDescriptor(");
    boolean first = true;

    sb.append("type:");
    if (this.type == null) {
      sb.append("null");
    } else {
      sb.append(this.type);
    }
    first = false;
    if (!first) sb.append(", ");
    sb.append("descFlags:");
    sb.append(this.descFlags);
    first = false;
    if (!first) sb.append(", ");
    sb.append("precision:");
    sb.append(this.precision);
    first = false;
    if (isSetScale()) {
      if (!first) sb.append(", ");
      sb.append("scale:");
      sb.append(this.scale);
      first = false;
    }
    if (isSetName()) {
      if (!first) sb.append(", ");
      sb.append("name:");
      if (this.name == null) {
        sb.append("null");
      } else {
        sb.append(this.name);
      }
      first = false;
    }
    if (isSetFullTableName()) {
      if (!first) sb.append(", ");
      sb.append("fullTableName:");
      if (this.fullTableName == null) {
        sb.append("null");
      } else {
        sb.append(this.fullTableName);
      }
      first = false;
    }
    if (isSetUdtTypeAndClassName()) {
      if (!first) sb.append(", ");
      sb.append("udtTypeAndClassName:");
      if (this.udtTypeAndClassName == null) {
        sb.append("null");
      } else {
        sb.append(this.udtTypeAndClassName);
      }
      first = false;
    }
    sb.append(")");
    return sb.toString();
  }

  public void validate() throws org.apache.thrift.TException {
    // check for required fields
    if (type == null) {
      throw new org.apache.thrift.protocol.TProtocolException("Required field 'type' was not present! Struct: " + toString());
    }
    // alas, we cannot check 'descFlags' because it's a primitive and you chose the non-beans generator.
    // alas, we cannot check 'precision' because it's a primitive and you chose the non-beans generator.
    // check for sub-struct validity
  }

  private void writeObject(java.io.ObjectOutputStream out) throws java.io.IOException {
    try {
      write(new org.apache.thrift.protocol.TCompactProtocol(new org.apache.thrift.transport.TIOStreamTransport(out)));
    } catch (org.apache.thrift.TException te) {
      throw new java.io.IOException(te);
    }
  }

  private void readObject(java.io.ObjectInputStream in) throws java.io.IOException, ClassNotFoundException {
    try {
      // it doesn't seem like you should have to do this, but java serialization is wacky, and doesn't call the default constructor.
      __isset_bitfield = 0;
      read(new org.apache.thrift.protocol.TCompactProtocol(new org.apache.thrift.transport.TIOStreamTransport(in)));
    } catch (org.apache.thrift.TException te) {
      throw new java.io.IOException(te);
    }
  }

  private static class ColumnDescriptorStandardSchemeFactory implements SchemeFactory {
    public ColumnDescriptorStandardScheme getScheme() {
      return new ColumnDescriptorStandardScheme();
    }
  }

  private static class ColumnDescriptorStandardScheme extends StandardScheme<ColumnDescriptor> {

    public void read(org.apache.thrift.protocol.TProtocol iprot, ColumnDescriptor struct) throws org.apache.thrift.TException {
      org.apache.thrift.protocol.TField schemeField;
      iprot.readStructBegin();
      while (true)
      {
        schemeField = iprot.readFieldBegin();
        if (schemeField.type == org.apache.thrift.protocol.TType.STOP) { 
          break;
        }
        switch (schemeField.id) {
          case 1: // TYPE
            if (schemeField.type == org.apache.thrift.protocol.TType.I32) {
              struct.type = GFXDType.findByValue(iprot.readI32());
              struct.setTypeIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 2: // DESC_FLAGS
            if (schemeField.type == org.apache.thrift.protocol.TType.I16) {
              struct.descFlags = iprot.readI16();
              struct.setDescFlagsIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 3: // PRECISION
            if (schemeField.type == org.apache.thrift.protocol.TType.I16) {
              struct.precision = iprot.readI16();
              struct.setPrecisionIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 4: // SCALE
            if (schemeField.type == org.apache.thrift.protocol.TType.I16) {
              struct.scale = iprot.readI16();
              struct.setScaleIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 5: // NAME
            if (schemeField.type == org.apache.thrift.protocol.TType.STRING) {
              struct.name = iprot.readString();
              struct.setNameIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 6: // FULL_TABLE_NAME
            if (schemeField.type == org.apache.thrift.protocol.TType.STRING) {
              struct.fullTableName = iprot.readString();
              struct.setFullTableNameIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 7: // UDT_TYPE_AND_CLASS_NAME
            if (schemeField.type == org.apache.thrift.protocol.TType.STRING) {
              struct.udtTypeAndClassName = iprot.readString();
              struct.setUdtTypeAndClassNameIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          default:
            org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
        }
        iprot.readFieldEnd();
      }
      iprot.readStructEnd();

      // check for required fields of primitive type, which can't be checked in the validate method
      if (!struct.isSetDescFlags()) {
        throw new org.apache.thrift.protocol.TProtocolException("Required field 'descFlags' was not found in serialized data! Struct: " + toString());
      }
      if (!struct.isSetPrecision()) {
        throw new org.apache.thrift.protocol.TProtocolException("Required field 'precision' was not found in serialized data! Struct: " + toString());
      }
      struct.validate();
    }

    public void write(org.apache.thrift.protocol.TProtocol oprot, ColumnDescriptor struct) throws org.apache.thrift.TException {
      struct.validate();

      oprot.writeStructBegin(STRUCT_DESC);
      if (struct.type != null) {
        oprot.writeFieldBegin(TYPE_FIELD_DESC);
        oprot.writeI32(struct.type.getValue());
        oprot.writeFieldEnd();
      }
      oprot.writeFieldBegin(DESC_FLAGS_FIELD_DESC);
      oprot.writeI16(struct.descFlags);
      oprot.writeFieldEnd();
      oprot.writeFieldBegin(PRECISION_FIELD_DESC);
      oprot.writeI16(struct.precision);
      oprot.writeFieldEnd();
      if (struct.isSetScale()) {
        oprot.writeFieldBegin(SCALE_FIELD_DESC);
        oprot.writeI16(struct.scale);
        oprot.writeFieldEnd();
      }
      if (struct.name != null) {
        if (struct.isSetName()) {
          oprot.writeFieldBegin(NAME_FIELD_DESC);
          oprot.writeString(struct.name);
          oprot.writeFieldEnd();
        }
      }
      if (struct.fullTableName != null) {
        if (struct.isSetFullTableName()) {
          oprot.writeFieldBegin(FULL_TABLE_NAME_FIELD_DESC);
          oprot.writeString(struct.fullTableName);
          oprot.writeFieldEnd();
        }
      }
      if (struct.udtTypeAndClassName != null) {
        if (struct.isSetUdtTypeAndClassName()) {
          oprot.writeFieldBegin(UDT_TYPE_AND_CLASS_NAME_FIELD_DESC);
          oprot.writeString(struct.udtTypeAndClassName);
          oprot.writeFieldEnd();
        }
      }
      oprot.writeFieldStop();
      oprot.writeStructEnd();
    }

  }

  private static class ColumnDescriptorTupleSchemeFactory implements SchemeFactory {
    public ColumnDescriptorTupleScheme getScheme() {
      return new ColumnDescriptorTupleScheme();
    }
  }

  private static class ColumnDescriptorTupleScheme extends TupleScheme<ColumnDescriptor> {

    @Override
    public void write(org.apache.thrift.protocol.TProtocol prot, ColumnDescriptor struct) throws org.apache.thrift.TException {
      TTupleProtocol oprot = (TTupleProtocol) prot;
      oprot.writeI32(struct.type.getValue());
      oprot.writeI16(struct.descFlags);
      oprot.writeI16(struct.precision);
      BitSet optionals = new BitSet();
      if (struct.isSetScale()) {
        optionals.set(0);
      }
      if (struct.isSetName()) {
        optionals.set(1);
      }
      if (struct.isSetFullTableName()) {
        optionals.set(2);
      }
      if (struct.isSetUdtTypeAndClassName()) {
        optionals.set(3);
      }
      oprot.writeBitSet(optionals, 4);
      if (struct.isSetScale()) {
        oprot.writeI16(struct.scale);
      }
      if (struct.isSetName()) {
        oprot.writeString(struct.name);
      }
      if (struct.isSetFullTableName()) {
        oprot.writeString(struct.fullTableName);
      }
      if (struct.isSetUdtTypeAndClassName()) {
        oprot.writeString(struct.udtTypeAndClassName);
      }
    }

    @Override
    public void read(org.apache.thrift.protocol.TProtocol prot, ColumnDescriptor struct) throws org.apache.thrift.TException {
      TTupleProtocol iprot = (TTupleProtocol) prot;
      struct.type = GFXDType.findByValue(iprot.readI32());
      struct.setTypeIsSet(true);
      struct.descFlags = iprot.readI16();
      struct.setDescFlagsIsSet(true);
      struct.precision = iprot.readI16();
      struct.setPrecisionIsSet(true);
      BitSet incoming = iprot.readBitSet(4);
      if (incoming.get(0)) {
        struct.scale = iprot.readI16();
        struct.setScaleIsSet(true);
      }
      if (incoming.get(1)) {
        struct.name = iprot.readString();
        struct.setNameIsSet(true);
      }
      if (incoming.get(2)) {
        struct.fullTableName = iprot.readString();
        struct.setFullTableNameIsSet(true);
      }
      if (incoming.get(3)) {
        struct.udtTypeAndClassName = iprot.readString();
        struct.setUdtTypeAndClassNameIsSet(true);
      }
    }
  }

}

