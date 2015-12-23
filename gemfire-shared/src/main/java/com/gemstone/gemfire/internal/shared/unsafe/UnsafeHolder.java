/*
 * Copyright (c) 2010-2015 Pivotal Software, Inc. All rights reserved.
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

package com.gemstone.gemfire.internal.shared.unsafe;

import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;

import com.gemstone.gemfire.internal.shared.ChannelBufferFramedInputStream;
import com.gemstone.gemfire.internal.shared.ChannelBufferFramedOutputStream;
import com.gemstone.gemfire.internal.shared.ChannelBufferInputStream;
import com.gemstone.gemfire.internal.shared.ChannelBufferOutputStream;
import com.gemstone.gemfire.internal.shared.InputStreamChannel;
import com.gemstone.gemfire.internal.shared.OutputStreamChannel;

/**
 * Holder for static sun.misc.Unsafe instance and some convenience methods. Use
 * other methods only if {@link UnsafeHolder#hasUnsafe()} returns true;
 * 
 * @author swale
 * @since gfxd 1.1
 */
public abstract class UnsafeHolder {

  private static final class Wrapper {

    static final sun.misc.Unsafe unsafe;

    static {
      sun.misc.Unsafe v = null;
      // try using "theUnsafe" field
      try {
        Field field = sun.misc.Unsafe.class.getDeclaredField("theUnsafe");
        field.setAccessible(true);
        v = (sun.misc.Unsafe)field.get(null);
      } catch (LinkageError le) {
        throw le;
      } catch (Throwable t) {
        throw new ExceptionInInitializerError(t);
      }
      if (v == null) {
        throw new ExceptionInInitializerError("theUnsafe not found");
      }
      unsafe = v;
    }

    static void init() {
    }
  }

  private static final boolean hasUnsafe;
  private static final Method directByteBufferAddressMethod;
  // Cached array base offset
  public static final long arrayBaseOffset;

  static {
    boolean v;
    long arrayOffset = -1;
    try {
      Wrapper.init();
      // try to access arrayBaseOffset via unsafe
      arrayOffset = (long)Wrapper.unsafe.arrayBaseOffset(byte[].class);
      v = true;
    } catch (LinkageError le) {
      le.printStackTrace();
      v = false;
    }
    hasUnsafe = v;
    arrayBaseOffset = arrayOffset;

    // check for "address()" method within DirectByteBuffer
    if (hasUnsafe) {
      Method m;
      ByteBuffer testBuf = ByteBuffer.allocateDirect(1);
      try {
        m = testBuf.getClass().getDeclaredMethod("address");
        m.setAccessible(true);
      } catch (Exception e) {
        m = null;
      }
      directByteBufferAddressMethod = m;
    }
    else {
      directByteBufferAddressMethod = null;
    }
  }

  private UnsafeHolder() {
    // no instance
  }

  public static boolean hasUnsafe() {
    return hasUnsafe;
  }

  public static Method getDirectByteBufferAddressMethod() {
    return directByteBufferAddressMethod;
  }

  public static sun.misc.Unsafe getUnsafe() {
    return Wrapper.unsafe;
  }

  @SuppressWarnings("resource")
  public static InputStreamChannel newChannelBufferInputStream(
      ReadableByteChannel channel, int bufferSize) throws IOException {
    return (directByteBufferAddressMethod != null
        ? new ChannelBufferUnsafeInputStream(channel, bufferSize)
        : new ChannelBufferInputStream(channel, bufferSize));
  }

  @SuppressWarnings("resource")
  public static OutputStreamChannel newChannelBufferOutputStream(
      WritableByteChannel channel, int bufferSize) throws IOException {
    return (directByteBufferAddressMethod != null
        ? new ChannelBufferUnsafeOutputStream(channel, bufferSize)
        : new ChannelBufferOutputStream(channel, bufferSize));
  }

  @SuppressWarnings("resource")
  public static InputStreamChannel newChannelBufferFramedInputStream(
      ReadableByteChannel channel, int bufferSize) throws IOException {
    return (directByteBufferAddressMethod != null
        ? new ChannelBufferUnsafeFramedInputStream(channel, bufferSize)
        : new ChannelBufferFramedInputStream(channel, bufferSize));
  }

  @SuppressWarnings("resource")
  public static OutputStreamChannel newChannelBufferFramedOutputStream(
      WritableByteChannel channel, int bufferSize) throws IOException {
    return (directByteBufferAddressMethod != null
        ? new ChannelBufferUnsafeFramedOutputStream(channel, bufferSize)
        : new ChannelBufferFramedOutputStream(channel, bufferSize));
  }

  // This number limits the number of bytes to copy per call to Unsafe's
  // copyMemory method. A limit is imposed to allow for safepoint polling
  // during a large copy
  static final long UNSAFE_COPY_THRESHOLD = 1024L * 1024L;

  // This number represents the point at which we have empirically
  // determined that the average cost of a JNI call exceeds the expense
  // of an element by element copy. This number may change over time.
  static final int JNI_ARRAY_COPY_THRESHOLD = 6;

  /**
   * Copy from source address into given destination array.
   * <p>
   * Code is from package-private <code>java.nio.Bits.copyToArray</code>.
   * 
   * @param srcAddr
   *          source address
   * @param dst
   *          destination array
   * @param dstBaseOffset
   *          offset of first element of storage in destination array
   * @param dstPos
   *          offset within destination array of the first element to write
   * @param length
   *          number of bytes to copy
   */
  public static void copyToArray(long srcAddr, Object dst, long dstBaseOffset,
      long dstPos, long length, final sun.misc.Unsafe unsafe) {
    long offset = dstBaseOffset + dstPos;
    while (length > 0) {
      long size = (length > UNSAFE_COPY_THRESHOLD) ? UNSAFE_COPY_THRESHOLD
          : length;
      unsafe.copyMemory(null, srcAddr, dst, offset, size);
      length -= size;
      srcAddr += size;
      offset += size;
    }
  }

  /**
   * Copy from given source array to destination address.
   * <p>
   * Code is from package-private <code>java.nio.Bits.copyFromArray</code>.
   * 
   * @param src
   *          source array
   * @param srcBaseOffset
   *          offset of first element of storage in source array
   * @param srcPos
   *          offset within source array of the first element to read
   * @param dstAddr
   *          destination address
   * @param length
   *          number of bytes to copy
   */
  static void copyFromArray(Object src, long srcBaseOffset, long srcPos,
      long dstAddr, long length, final sun.misc.Unsafe unsafe) {
    long offset = srcBaseOffset + srcPos;
    while (length > 0) {
      long size = (length > UNSAFE_COPY_THRESHOLD) ? UNSAFE_COPY_THRESHOLD
          : length;
      unsafe.copyMemory(src, offset, null, dstAddr, size);
      length -= size;
      offset += size;
      dstAddr += size;
    }
  }

  public static boolean checkBounds(int off, int len, int size) {
    return ((off | len | (off + len) | (size - (off + len))) >= 0);
  }

  /**
   * @see ByteBuffer#get(byte[], int, int)
   */
  public static void bufferGet(final byte[] dst, long address, int offset,
      final int length, final sun.misc.Unsafe unsafe) {
    if (length > JNI_ARRAY_COPY_THRESHOLD) {
      copyToArray(address, dst, arrayBaseOffset, offset << 0, length << 0,
          unsafe);
    }
    else {
      final int end = offset + length;
      while (offset < end) {
        dst[offset] = unsafe.getByte(address);
        address++;
        offset++;
      }
    }
  }

  /**
   * @see ByteBuffer#put(byte[], int, int)
   */
  public static void bufferPut(final byte[] src, long address, int offset,
      final int length, final sun.misc.Unsafe unsafe) {
    if (length > JNI_ARRAY_COPY_THRESHOLD) {
      copyFromArray(src, arrayBaseOffset, offset << 0, address, length << 0,
          unsafe);
    }
    else {
      final int end = offset + length;
      while (offset < end) {
        unsafe.putByte(address, src[offset]);
        address++;
        offset++;
      }
    }
  }
}
