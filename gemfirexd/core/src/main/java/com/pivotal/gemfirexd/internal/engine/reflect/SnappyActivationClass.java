package com.pivotal.gemfirexd.internal.engine.reflect;

import com.pivotal.gemfirexd.internal.engine.sql.execute.SnappyActivation;
import com.pivotal.gemfirexd.internal.iapi.error.StandardException;
import com.pivotal.gemfirexd.internal.iapi.services.loader.GeneratedClass;
import com.pivotal.gemfirexd.internal.iapi.services.loader.GeneratedMethod;
import com.pivotal.gemfirexd.internal.iapi.sql.conn.LanguageConnectionContext;
import com.pivotal.gemfirexd.internal.iapi.sql.execute.ExecPreparedStatement;

/**
 * Created by kneeraj on 21/10/15.
 */
public class SnappyActivationClass implements GeneratedClass {
  boolean returnRows;
  public SnappyActivationClass(boolean returnRows) {
    this.returnRows = returnRows;
  }

  public int getClassLoaderVersion() {
    return 0;
  }

  public GeneratedMethod getMethod(String simpleName) throws StandardException {
    return null;
  }

  public final String getName() {
    return "SnappyActivation";
  }

  public final Object newInstance(final LanguageConnectionContext lcc,
                                  final boolean addToLCC, final ExecPreparedStatement eps)
    throws StandardException {
    return new SnappyActivation(lcc, eps, this.returnRows);
  }
}
