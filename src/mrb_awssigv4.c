/*
** mrb_awssigv4.c - AwsSigv4 class
**
** Copyright (c) Okumura Takahiro 2018
**
** See Copyright Notice in LICENSE
*/

#include "mruby.h"
#include "mruby/data.h"
#include "mrb_awssigv4.h"

#define DONE mrb_gc_arena_restore(mrb, 0);

typedef struct {
  char *str;
  int len;
} mrb_awssigv4_data;

static const struct mrb_data_type mrb_awssigv4_data_type = {
  "mrb_awssigv4_data", mrb_free,
};

static mrb_value mrb_awssigv4_init(mrb_state *mrb, mrb_value self)
{
  mrb_awssigv4_data *data;
  char *str;
  int len;

  data = (mrb_awssigv4_data *)DATA_PTR(self);
  if (data) {
    mrb_free(mrb, data);
  }
  DATA_TYPE(self) = &mrb_awssigv4_data_type;
  DATA_PTR(self) = NULL;

  mrb_get_args(mrb, "s", &str, &len);
  data = (mrb_awssigv4_data *)mrb_malloc(mrb, sizeof(mrb_awssigv4_data));
  data->str = str;
  data->len = len;
  DATA_PTR(self) = data;

  return self;
}

static mrb_value mrb_awssigv4_hello(mrb_state *mrb, mrb_value self)
{
  mrb_awssigv4_data *data = DATA_PTR(self);

  return mrb_str_new(mrb, data->str, data->len);
}

static mrb_value mrb_awssigv4_hi(mrb_state *mrb, mrb_value self)
{
  return mrb_str_new_cstr(mrb, "hi!!");
}

void mrb_mruby_aws_sigv4_gem_init(mrb_state *mrb)
{
  struct RClass *awssigv4;
  awssigv4 = mrb_define_class(mrb, "AwsSigv4", mrb->object_class);
  mrb_define_method(mrb, awssigv4, "initialize", mrb_awssigv4_init, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, awssigv4, "hello", mrb_awssigv4_hello, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, awssigv4, "hi", mrb_awssigv4_hi, MRB_ARGS_NONE());
  DONE;
}

void mrb_mruby_aws_sigv4_gem_final(mrb_state *mrb)
{
}

